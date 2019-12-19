defmodule Zappa do
  @moduledoc """
  This implementation relies on tail recursion (and not regular expressions).
  Zappa is a Handlebars to EEx [transpiler](https://en.wikipedia.org/wiki/Source-to-source_compiler).

    Helpers:
    functions receive a %Tag{} struct

    Blocks:
    functions receive a %Tag{} struct and the contents of the block

    Partials:
    functions receive a %Tag{} struct


  Handlebar Tags:
  ```
  # {{ regular tag (html escaped)
  # {{{ non-escaped tag
  # {{! comment
  # {{!-- comment --}}
  # {{> partial
  # {{# block
  # {{{{raw-helper}}}}
  ```
  """
  alias Zappa.{
    Helpers,
    Tag
  }

  require Logger

  # A [Handlebars.js](https://handlebarsjs.com/) template (as a string). [Try it](http://tryhandlebarsjs.com/)!
  @typep handlebars_template :: String.t()

  @typep eex_template :: String.t()

  # The string being parsed, from the active point to the end.
  @typep head :: String.t()
  # The rest of the string
  @typep tail :: String.t()
  # A string denoting the beginning or end of a tag, e.g. }}
  @typep delimiter :: String.t()
  # Denotes a string used to collect
  @typep accumulator :: String.t()

  # A list where the first item represents the block that is in context. This is used as the parser traverses down
  # into nested blocks, e.g. {{if something}}{{if something_else}}some text{{/if}}{{/if}}
  # It affects the validation of the closing tag (e.g. {{/if}}): a closing tag is only valid if it closes the current
  # block context
  @typep block_contexts :: list()

  @default_helper_callback &Zappa.Helpers.Default.parse_default/1

  @default_helpers %Zappa.Helpers{
    helpers: %{
      "else" => &Zappa.Helpers.Else.parse_else/1,
      "log" => &Zappa.Helpers.Log.parse_log/1,
      "__default__" => &Zappa.Helpers.Default.parse_default/1
    },
    block_helpers: %{
      "if" => &Zappa.BlockHelpers.If.parse_if/1,
      "each" => &Zappa.BlockHelpers.Each.parse_each/1,
      "unless" => &Zappa.BlockHelpers.Unless.parse_unless/1
    },
    partials: %{}
  }

  @doc """
  Evaluate the handlebars string and return the result. (The name is borrowed the name from EEx.eval_string)
  """
  @spec eval_string(handlebars_template, list) :: String.t()
  def eval_string(handlebars_template, values_list) do
    compile(handlebars_template)
    |> EEx.eval_string(values_list)
  end

  @doc """
  Optionally, you may wish to register and supply your own helper functions to augment or replace the defaults
  available via `get_default_helpers/0`.
  """
  @spec eval_string(handlebars_template, list, map) :: String.t()
  def eval_string(handlebars_template, values_list, helpers) do
    compile(handlebars_template, helpers)
    |> EEx.eval_string(values_list)
  end

  @doc """
  Retrieve the default helpers supported
  """
  @spec get_default_helpers() :: %Zappa.Helpers{}
  def get_default_helpers, do: @default_helpers

  @doc """
  Compiles a handlebars template to EEx using the default helpers (if, with, unless, etc.).
  See get_default_helpers/0


  ## Examples

      iex> handlebars_template = "Hello {{thing}}"
      iex> Zappa.compile(handlebars_template)
      "Hello <%= thing %>"

  """
  @spec compile(handlebars_template) :: {:ok, eex_template} | {:error, String.t()}
  def compile(template), do: compile(template, get_default_helpers())

  @doc """
  Compiles a handlebars template to EEx using the helpers provided.

  """
  @spec compile(handlebars_template, map) :: {:ok, eex_template} | {:error, String.t()}
  def compile(template, helpers) do
    template
    |> strip_eex()
    |> parse("", helpers, [])
  end

  # Ideally, we would accumulate for the current block until it ends
  # Starting:
  # []  -- the root context
  # ["if"] -- we've entered into an if block
  # ["each", "if"] -- inside the if-block, there was an "each" block
  # defp parse("", acc, _helpers, block_context_list), do: {:ok, acc}

  # {{ regular tag (html escaped)
  # {{{ non-escaped tag
  # {{! comment
  # {{!-- comment --}}
  # {{> partial
  # {{# block
  # {{{{raw-helper}}}}
  @spec parse(handlebars_template, accumulator, map, block_contexts) ::
          {:ok, String.t()} | {:error, String.t()}
  # End of handlebars template! All done!
  defp parse("", acc, _helpers, []), do: {:ok, acc}

  defp parse("", acc, _helpers, [block | _]) do
    {:error, "Unexpected end of template.  Closing block not found: {{/#{block}}}"}
  end

  ######################################################################################################################
  # Comment tag
  defp parse("{{!--" <> tail, acc, helpers, block_contexts) do
    case accumulate_tag(tail, "--}}") do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.contents}%>", helpers, block_contexts)
      {:error, message} -> {:error, message}
    end
  end

  ######################################################################################################################
  # Comment tag
  defp parse("{{!" <> tail, acc, helpers, block_contexts) do
    case accumulate_tag(tail) do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.contents}%>", helpers, block_contexts)
      {:error, message} -> {:error, message}
    end
  end

  ######################################################################################################################
  # Block open
  defp parse("{{#" <> tail, acc, helpers, block_contexts) do
    with {:ok, tag, tail} <- accumulate_tag(tail),
         :ok <- validate_opening_block_tag(tag),
         {:ok, callback} <- get_block_helper(helpers, tag.name),
         {:ok, block_content, tail, block_contexts} <-
           parse(tail, "", helpers, [tag.name | block_contexts]),
         {:ok, content} <- call_function(callback, Map.put(tag, :block_contents, block_content)) do
      parse(tail, acc <> content, helpers, block_contexts)
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec validate_opening_block_tag(%Tag{}) :: {:error, String.t()}
  defp validate_opening_block_tag(%Tag{name: ""}) do
    {:error, "Opening block tags require a name, e.g. {{#foo}}"}
  end

  @spec validate_opening_block_tag(%Tag{}) :: {:error, String.t()} | :ok
  defp validate_opening_block_tag(tag), do: :ok

  @spec get_block_helper(%Helpers{}, String.t()) :: {:ok, function}
  defp get_block_helper(%Helpers{block_helpers: block_helpers}, name) do
    {
      :ok,
      Map.get(
        block_helpers,
        name,
        fn tag -> {:error, "Block-helper not registered: #{tag.name}"} end
      )
    }
  end

  ######################################################################################################################
  # Block close. Blocks must close the tag that opened.
  defp parse("{{/" <> tail, acc, helpers, []) do
    {:error, "Unexpected closing block tag."}
  end

  defp parse("{{/" <> tail, acc, helpers, [active_block | block_contexts]) do
    with {:ok, tag, tail} <- accumulate_tag(tail),
         :ok <- validate_closing_block_tag(tag, active_block) do
      {:ok, acc, tail, block_contexts}
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec validate_closing_block_tag(%Tag{}, String.t()) :: {:error, String.t()}
  defp validate_closing_block_tag(%Tag{name: ""}, _active_block) do
    {:error, "Block closing tags require a name, e.g. {{/foo}}"}
  end

  @spec validate_closing_block_tag(%Tag{}, String.t()) :: {:error, String.t()} | :ok
  defp validate_closing_block_tag(tag, active_block) do
    if tag.name != active_block do
      {:error, "Unexpected closing block tag. Expected closing {{/#{active_block}}} tag."}
    else
      :ok
    end
  end

  ######################################################################################################################
  # Partial
  defp parse("{{>" <> tail, acc, helpers, block_contexts) do
    with {:ok, tag, tail} <- accumulate_tag(tail),
         :ok <- validate_partial_tag(tag),
         {:ok, callback} <- get_partial_helper(helpers, tag.name),
         {:ok, unparsed_content} <- call_function(callback, tag),
         {:ok, parsed_content} <- parse(unparsed_content, "", helpers, block_contexts) do
      parse(tail, acc <> parsed_content, helpers, block_contexts)
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec validate_partial_tag(%Tag{}) :: {:error, String.t()}
  defp validate_partial_tag(%Tag{name: ""}) do
    {:error, "Partial tags require a name, e.g. {{>foo}}"}
  end

  @spec validate_partial_tag(%Tag{}) :: :ok
  defp validate_partial_tag(tag), do: :ok

  # Wraps the output in a function if only a string was registered
  @spec get_partial_helper(%Helpers{}, String.t()) :: {:ok, function}
  defp get_partial_helper(%Helpers{partials: partial_helpers}, name) do
    handler =
      Map.get(
        partial_helpers,
        name,
        fn tag -> {:error, "Partial not registered: #{tag.name}"} end
      )

    case handler do
      handler when is_function(handler) -> {:ok, handler}
      handler -> {:ok, fn _ -> handler end}
    end
  end

  ######################################################################################################################
  # Non-escaped tag
  defp parse("{{{" <> tail, acc, helpers, block_contexts) do
    with {:ok, tag, tail} <- accumulate_tag(tail, "}}}"),
         :ok <- validate_non_escaped_tag(tag),
         {:ok, contents} <- render_non_escaped_tag(tag, helpers) do
      parse(tail, acc <> contents, helpers, block_contexts)
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec validate_non_escaped_tag(%Tag{}) :: {:error, String.t()}
  defp validate_non_escaped_tag(%Tag{name: ""}) do
    {:error, "Non-escaped tags require a name, e.g. {{{foo}}}"}
  end

  @spec validate_non_escaped_tag(%Tag{}) :: :ok
  defp validate_non_escaped_tag(%Tag{options: ""} = tag), do: :ok

  @spec validate_non_escaped_tag(%Tag{}) :: {:error, String.t()}
  defp validate_non_escaped_tag(_tag) do
    {:error, "Non-escaped tags should not include options"}
  end

  @spec render_non_escaped_tag(%Tag{}, %Helpers{}) :: {:ok, accumulator} | {:error, String.t()}
  defp render_non_escaped_tag(tag, _helpers) do
    {:ok, "<%= #{tag.name} %>"}
  end

  ######################################################################################################################
  # Regular tag (HTML-escaped)
  defp parse("{{" <> tail, acc, %Helpers{helpers: helper_map} = helpers, block_contexts) do
    with {:ok, tag, tail} <- accumulate_tag(tail),
         :ok <- validate_regular_tag(tag),
         {:ok, function} <- get_helper(helpers, tag.name),
         {:ok, contents} <- call_function(function, tag) do
      parse(tail, acc <> contents, helpers, block_contexts)
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec validate_regular_tag(%Tag{}) :: {:error, String.t()}
  defp validate_regular_tag(%Tag{name: ""}) do
    {:error, "Regular tags require a name, e.g. {{foo}}"}
  end

  @spec validate_regular_tag(%Tag{}) :: atom
  defp validate_regular_tag(tag), do: :ok

  # This getter is constructed so that one may override the default functionality, but it will always fall back to it.
  @spec get_helper(%Helpers{}, String.t()) :: {:ok, function}
  defp get_helper(%Helpers{helpers: helpers_map}, name) do
    {
      :ok,
      Map.get(
        helpers_map,
        name,
        Map.get(
          helpers_map,
          "__default__",
          @default_helper_callback
        )
      )
    }
  end

  ######################################################################################################################
  # Error: ending delimiter found
  # Try to include some information in the error message
  @spec parse(head, accumulator, %Helpers{}, String.t()) :: {:error, String.t()}
  defp parse("}}" <> tail, acc, _helpers, _block_contexts) do
    if String.length(acc) > 32 do
      <<first_chunk::binary-size(32)>> <> _ = acc
      {:error, "Unexpected closing delimiter: }}#{first_chunk}"}
    else
      {:error, "Unexpected closing delimiter: }}"}
    end
  end

  # Pass-thru: when we're not in a tag, the character at the head goes appended to the accumulator
  defp parse(<<head::binary-size(1)>> <> tail, acc, helpers, block_contexts),
    do: parse(tail, acc <> head, helpers, block_contexts)

  ######################################################################################################################
  # This block is devoted to finding the tag and returning data about it (as a %Tag{} struct)
  ######################################################################################################################
  @spec accumulate_tag(head, delimiter, accumulator) :: {:error, String.t()} | {:ok, %Tag{}, tail}
  defp accumulate_tag(head, ending_delimiter \\ "}}", tag_acc \\ "")
  defp accumulate_tag("", _ending_delimiter, _tag_acc), do: {:error, "Unclosed tag."}

  defp accumulate_tag(<<h::binary-size(4), tail::binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp accumulate_tag(<<h::binary-size(3), tail::binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp accumulate_tag(<<h::binary-size(2), tail::binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp accumulate_tag("{" <> tail, delimiter, tag_acc) do
    {:error, "Unexpected opening bracket inside a tag:{#{tail}"}
  end

  defp accumulate_tag(<<head::binary-size(1)>> <> tail, delimiter, tag_acc) do
    accumulate_tag(tail, delimiter, tag_acc <> head)
  end

  # https://elixirforum.com/t/how-to-detect-if-a-given-character-grapheme-is-whitespace/26735/5
  @spec make_tag_struct(accumulator, tail) :: {:error, String.t()} | {:ok, %Tag{}, tail}
  defp make_tag_struct(tag_acc, tail) do
    result = String.split(String.trim(tag_acc), ~r/\p{Zs}/u, parts: 2)

    case result do
      [tag_name] ->
        {:ok, %Tag{name: String.trim(tag_name), options: "", contents: tag_acc}, tail}

      [tag_name, tag_options] ->
        {
          :ok,
          %Tag{
            name: String.trim(tag_name),
            options: String.trim(tag_options),
            contents: tag_acc
          },
          tail
        }
    end
  end

  @doc """
  This removes all EEX tags from the input template.
  This is a security measure in case some nefarious user gets the sneaky idea to put EEX functions inside what should
  be a Handlebars template.
  TODO: better to do this via parsing action? Yes, it would be faster, but it would be harder to skip
  """
  def strip_eex(template) do
    regex = ~r/<%.*%>/U

    Regex.scan(regex, template)
    |> Enum.reduce(template, fn [x | _], acc -> String.replace(acc, x, "") end)
  end

  @doc """
  This is a convenience function that adds your helper callback to the %Zappa.Helpers{} struct.
  The callback function provided should take one argument representing the options included with the tag.

  ## Examples
      iex> helpers = Zappa.get_default_helpers()
        |> Zappa.register_helper("all_caps", fn(options) -> String.upcase(options) end)

  Then you would call your function in a template like this:
  ```
  <p>Here is my variable: {{all_caps my_var}}</p>
  ```

  """
  # TODO: helper names must not being with ./ etc.
  # See https://elixirforum.com/t/using-put-in-for-structs/27645
  @spec register_helper(%Helpers{}, String.t(), function) :: %Helpers{}
  def register_helper(helpers, name, callback), do: put_in(helpers.helpers[name], callback)

  @doc """
  This is a convenience function that adds your block helper callback to the %Zappa.Helpers{} struct.
  """
  @spec register_block(%Helpers{}, String.t(), function) :: %Helpers{}
  def register_block(helpers, name, callback), do: put_in(helpers.block_helpers[name], callback)

  @doc """
  This is a convenience function that adds your helper callback to the %Zappa.Helpers{} struct.
  """
  @spec register_partial(%Helpers{}, String.t(), function) :: %Helpers{}
  def register_partial(helpers, name, callback), do: put_in(helpers.partials[name], callback)

  @spec call_function(function, %Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  defp call_function(callback, tag) do
    callback.(tag)
    |> handle_function_output()
  end

  # Because user-registered functions may return a simple string instead of a tuple
  @spec handle_function_output(any) :: {:ok, String.t()} | {:error, String.t()}
  defp handle_function_output(output) do
    case output do
      {:ok, output} ->
        {:ok, output}

      {:error, error} ->
        {:error, error}

      string when is_binary(string) ->
        {:ok, string}

      _ ->
        {:error,
         "Invalid function output. Registered helper function output must be {:ok, String.t()} | {:error, String.t} | String.t"}
    end
  end
end
