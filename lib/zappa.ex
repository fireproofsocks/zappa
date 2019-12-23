defmodule Zappa do
  @moduledoc """
  This implementation relies on tail recursion (and not regular expressions).
  Zappa is a Handlebars to EEx [transpiler](https://en.wikipedia.org/wiki/Source-to-source_compiler).




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

  # These are defined separately because the parser will fall back to them if no callbacks are registered in the
  # %Zappa.Helpers{} struct.
  @default_escaped_callback &Zappa.Helpers.EscapedDefault.parse_escaped_default/1
  @default_unescaped_callback &Zappa.Helpers.UnescapedDefault.parse_unescaped_default/1

  @default_helpers %Zappa.Helpers{
    helpers: %{
      "else" => &Zappa.Helpers.Else.parse_else/1,
      "log" => &Zappa.Helpers.Log.parse_log/1,
      "__escaped__" => @default_escaped_callback,
      "__unescaped__" => @default_unescaped_callback
    },
    block_helpers: %{
      "if" => &Zappa.BlockHelpers.If.parse_if/1,
      "each" => &Zappa.BlockHelpers.Each.parse_each/1,
      "unless" => &Zappa.BlockHelpers.Unless.parse_unless/1
    },
    partials: %{}
  }

  # The regular expression used to detect if a supplied template contains any EEx expressions
  @eex_regex ~r/<%.*%>/U

  @doc """
  This is a convenience function that combines `Zappa.compile/1` and `EEx.eval_string/3`. This function is only
  recommended when performance is not a consideration because the handlebars template is (re)compiled each time.
  """
  @spec eval_string(handlebars_template, keyword) :: String.t()
  def eval_string(handlebars_template, values_list) do
    compile(handlebars_template)
    |> EEx.eval_string(values_list)
  end

  @doc """
  This is a convenience function that combines `Zappa.compile/2` and `EEx.eval_string/3` - it is behaves the same as
  `Zappa.eval_string/2`, but it accepts a `%Zappa.Helpers{}` struct. This function is only
  recommended when performance is not a consideration because the handlebars template is (re)compiled each time.
  """
  @spec eval_string(handlebars_template, keyword, %Zappa.Helpers{}) :: String.t()
  def eval_string(handlebars_template, values_list, %Zappa.Helpers{} = helpers) do
    compile(handlebars_template, helpers)
    |> EEx.eval_string(values_list)
  end

  @doc """
  Retrieves the regular-, block-, and partial-helpers registered by default.  This function is a useful starting place
  when you wish to add your own helpers to the defaults.

  ## Examples
      iex> helpers = Zappa.get_default_helpers()
      iex> helpers = Zappa.register_helper("random_number", fn(tag) -> 42 end)
      iex> {:ok, eex} = Zappa.compile("My favorite number is {{random_number}}", helpers)

  See the following functions for easily adding your own callbacks to the `%Zappa.Helpers{}` struct:
  - `Zappa.register_helper/3`
  - `Zappa.register_block/3`
  - `Zappa.register_partial/3`
  """
  @spec get_default_helpers() :: %Zappa.Helpers{}
  def get_default_helpers, do: @default_helpers

  @doc """
  Compiles a handlebars template to EEx using the default helpers (if, with, unless, etc.).
  See `Zappa.get_default_helpers/0`


  ## Examples

      iex> handlebars_template = "Hello {{{thing}}}"
      iex> Zappa.compile(handlebars_template)
      {:ok, "Hello <%= thing %>"}

  """
  @spec compile(handlebars_template) :: {:ok, eex_template} | {:error, String.t()}
  def compile(template), do: compile(template, get_default_helpers())


  @doc """
  Compiles a handlebars template to EEx using the helpers provided.  This is the function you want if you want to add
  your own helper functions to the processing.
  """
  @spec compile(handlebars_template, %Zappa.Helpers{}) ::
          {:ok, eex_template} | {:error, String.t()}
  def compile(template, %Zappa.Helpers{} = helpers) do
    case has_eex?(template) do
      true -> {:error, "Compilation unsafe: the source template contains EEx expressions."}
      false -> parse(template, "", helpers, [])
    end
  end

  @doc """
  This is a variant of the `Zappa.compile/1` function that raises an error instead of returning a tuple.  (I was
  told this was idiomatic Elixir).
  """
  @spec compile!(handlebars_template) :: eex_template
  def compile!(template) do
    compile(template, get_default_helpers())
    |> bangify()
  end

  @doc """
  This is a variant of the `Zappa.compile/2` function that raises an error instead of returning a tuple.
  """
  @spec compile!(handlebars_template, %Zappa.Helpers{}) :: eex_template
  def compile!(template, %Zappa.Helpers{} = helpers) do
    compile(template, helpers)
    |> bangify()
  end

  # TODO: {{{{raw-helper}}}}
  @spec parse(handlebars_template, accumulator, map, block_contexts) ::
          {:ok, String.t()} | {:error, String.t()}
  # End of handlebars template! All done!
  defp parse("", acc, _helpers, []), do: {:ok, acc}

  defp parse("", _acc, _helpers, [block | _]) do
    {:error, "Unexpected end of template.  Closing block not found: {{/#{block}}}"}
  end

  ######################################################################################################################
  # Comment tag
  defp parse("{{!--" <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts) do
    case accumulate_tag(tail, "--}}") do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.raw_contents}%>", helpers, block_contexts)
      {:error, message} -> {:error, message}
    end
  end

  ######################################################################################################################
  # Comment tag
  defp parse("{{!" <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts) do
    case accumulate_tag(tail) do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.raw_contents}%>", helpers, block_contexts)
      {:error, message} -> {:error, message}
    end
  end

  ######################################################################################################################
  # Block open
  defp parse("{{#" <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts) do
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
  defp validate_opening_block_tag(_tag), do: :ok

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
  defp parse("{{/" <> _tail, _acc, _helpers, []) do
    {:error, "Unexpected closing block tag."}
  end

  defp parse("{{/" <> tail, acc, _helpers, [active_block | block_contexts]) do
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
  defp parse("{{>" <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts) do
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
  defp validate_partial_tag(_tag), do: :ok

  @spec get_partial_helper(%Helpers{}, String.t()) :: {:ok, function}
  defp get_partial_helper(%Helpers{partials: partial_helpers}, name) do
    handler =
      Map.get(
        partial_helpers,
        name,
        fn tag -> {:error, "Partial not registered: #{tag.name}"} end
      )

    # For convenience/normalization, we wrap the output in a function if only a string was registered
    case handler do
      handler when is_function(handler) -> {:ok, handler}
      handler -> {:ok, fn _ -> handler end}
    end
  end

  ######################################################################################################################
  # Non-escaped tag
  defp parse("{{{" <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts) do
    with {:ok, tag, tail} <- accumulate_tag(tail, "}}}"),
         :ok <- validate_non_escaped_tag(tag),
         {:ok, function} <- get_unescaped_helper(helpers),
         {:ok, contents} <- call_function(function, tag) do
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
  defp validate_non_escaped_tag(%Tag{options: ""}), do: :ok

  @spec validate_non_escaped_tag(%Tag{}) :: {:error, String.t()}
  defp validate_non_escaped_tag(_tag) do
    {:error, "Non-escaped tags should not include options"}
  end

  ######################################################################################################################
  # Regular tag (HTML-escaped)
  defp parse("{{" <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts) do
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
  defp validate_regular_tag(_tag), do: :ok

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
          "__escaped__",
          @default_escaped_callback
        )
      )
    }
  end

  @spec get_unescaped_helper(%Helpers{}) :: {:ok, function}
  defp get_unescaped_helper(%Helpers{helpers: helpers_map}) do
    {
      :ok,
      Map.get(
        helpers_map,
        "__unescaped__",
        @default_unescaped_callback
      )
    }
  end

  ######################################################################################################################
  # Error: ending delimiter found
  # Try to include some information in the error message
  @spec parse(head, accumulator, %Helpers{}, String.t()) :: {:error, String.t()}
  defp parse("}}" <> _tail, acc, _helpers, _block_contexts) do
    if String.length(acc) > 32 do
      <<first_chunk :: binary - size(32)>> <> _ = acc
      {:error, "Unexpected closing delimiter: }}#{first_chunk}"}
    else
      {:error, "Unexpected closing delimiter: }}"}
    end
  end

  # Pass-thru: when we're not in a tag, the character at the head goes appended to the accumulator
  defp parse(<<head :: binary - size(1)>> <> tail, acc, %Zappa.Helpers{} = helpers, block_contexts),
       do: parse(tail, acc <> head, helpers, block_contexts)

  ######################################################################################################################
  # This block is devoted to finding the tag and returning data about it (as a %Tag{} struct)
  ######################################################################################################################
  @spec accumulate_tag(head, delimiter, accumulator) :: {:error, String.t()} | {:ok, %Tag{}, tail}
  defp accumulate_tag(head, ending_delimiter \\ "}}", tag_acc \\ "")
  defp accumulate_tag("", _ending_delimiter, _tag_acc), do: {:error, "Unclosed tag."}

  defp accumulate_tag(<<h :: binary - size(4), tail :: binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp accumulate_tag(<<h :: binary - size(3), tail :: binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp accumulate_tag(<<h :: binary - size(2), tail :: binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp accumulate_tag("{" <> tail, _delimiter, _tag_acc) do
    {:error, "Unexpected opening bracket inside a tag:{#{tail}"}
  end

  defp accumulate_tag(<<head :: binary - size(1)>> <> tail, delimiter, tag_acc) do
    accumulate_tag(tail, delimiter, tag_acc <> head)
  end

  # https://elixirforum.com/t/how-to-detect-if-a-given-character-grapheme-is-whitespace/26735/5
  @spec make_tag_struct(accumulator, tail) :: {:error, String.t()} | {:ok, %Tag{}, tail}
  defp make_tag_struct(tag_acc, tail) do
    result = String.split(String.trim(tag_acc), ~r/\p{Zs}/u, parts: 2)

    case result do
      [tag_name] ->
        {:ok, %Tag{name: String.trim(tag_name), options: "", raw_contents: tag_acc}, tail}

      [tag_name, tag_options] ->
        {
          :ok,
          %Tag{
            name: String.trim(tag_name),
            options: String.trim(tag_options),
            raw_contents: tag_acc
          },
          tail
        }
    end
  end

  # Detect if the given string contains EEx expressions
  @spec has_eex?(handlebars_template) :: boolean
  defp has_eex?(template), do: Regex.match?(@eex_regex, template)


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
        {
          :error,
          "Invalid function output. Registered helper function output must be {:ok, String.t()} | {:error, String.t} | String.t"
        }
    end
  end

  @spec bangify({atom, String.t}) :: eex_template
  defp bangify(result) do
    case result do
      {:ok, eex} -> eex
      {:error, message} -> raise message
    end
  end
end