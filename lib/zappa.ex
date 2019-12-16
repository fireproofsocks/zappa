defmodule Zappa do
  @moduledoc """
  This implementation relies on tail recursion (and not regular expressions).
  Zappa is a Handlebars to EEx [transpiler](https://en.wikipedia.org/wiki/Source-to-source_compiler).
  """
  alias Zappa.Tag
  require Logger

  # Types to help make the the specs and function documentation more clear.
  @typedoc """
  A [Handlebars.js](https://handlebarsjs.com/) template (as a string). [Try it](http://tryhandlebarsjs.com/)!
  """
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

  @doc """
  Evaluate the handlebars string and return the result. (The name is borrowed the name from EEx.eval_string)
  """
  @spec eval_string(handlebars_template, list) :: String.t()
  def eval_string(handlebars_template, values_list) do
    handlebars2eex(handlebars_template)
    |> EEx.eval_string(values_list)
  end

  @spec eval_string(handlebars_template, list, map) :: String.t()
  def eval_string(handlebars_template, values_list, helpers) do
    handlebars2eex(handlebars_template, helpers)
    |> EEx.eval_string(values_list)
  end

  @doc """
  Retrieve the default helpers supported
  """
  @spec get_default_helpers() :: map
  def get_default_helpers() do
    %{
      "if" => &Zappa.BlockHelpers.If.parse_if/0,
      # "else"
    }
  end

  @doc """
  Compiles a handlebars template to EEx using the default helpers (if, with, unless, etc.).
  See get_default_helpers/0


  ## Examples

      iex> handlebars_template = "Hello {{thing}}"
      iex> Zappa.handlebars2eex(handlebars_template)
      "Hello <%= thing %>"

  """
  @spec handlebars2eex(handlebars_template) :: {:ok, eex_template} | {:error, String.t()}
  def handlebars2eex(template), do: handlebars2eex(template, get_default_helpers())

  @doc """
  Compiles a handlebars template to EEx using the helpers provided.

  """
  @spec handlebars2eex(handlebars_template, map) :: {:ok, eex_template} | {:error, String.t()}
  def handlebars2eex(template, helpers) do
    template
    |> strip_eex()
    |> parse("", helpers)
#    |> parse("", helpers, [])
  end

  # Ideally, we would accumulate for the current block until it ends
  # Starting:
  # []  -- the root context
  # ["if"] -- we've entered into an if block
  # ["each", "if"] -- inside the if-block, there was an "each" block
  # We've got to be able to juggle the accumulators according to their context... I think this will get handled automatically
  # defp parse("", acc, _helpers, block_context_list), do: {:ok, acc}

  # {{ regular tag (html escaped)
  # {{{ non-escaped tag
  # {{! comment
  # {{!-- comment --}}
  # {{> partial
  # {{# block
  # {{{{raw-helper}}}}
  @spec parse(handlebars_template, accumulator, map) :: {:ok, String.t()} | {:error, String.t()}
  # End of handlebars template! All done!
  defp parse("", acc, _helpers), do: {:ok, acc}

  # Comment tag
  defp parse("{{!--" <> tail, acc, helpers) do
    result = accumulate_tag(tail, "--}}")

    case result do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Comment tag
  defp parse("{{!" <> tail, acc, helpers) do
    result = accumulate_tag(tail)

    case result do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Block open
  defp parse("{{#" <> tail, acc, helpers) do
    result = accumulate_tag(tail)
    # Get name of block helper
    # accumulate the block {{/block}}
    #    block_name = "if"
    #    helpers[block_name].()
    case result do
      {:ok, %Tag{name: ""}, _tail} ->
        {:error, "Block tags require a name, e.g. {{#foo}}  {{/foo}}"}

      {:ok, tag, tail} ->
        partial = get_helper(helpers, tag.name)

        case partial do
          {:ok, callback} -> parse(resolve_partial(callback, tag.options) <> tail, acc, helpers)
          {:error, message} -> {:error, message}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  # Block close. Blocks must close the tag that opened.
  defp parse("{{/" <> tail, acc, helpers) do
    result = accumulate_tag(tail)

    case result do
      {:ok, _tag, _tail} ->
        {:error, "Unexpected closing block tag."}
    end
  end
  # Partial
  defp parse("{{>" <> tail, acc, helpers) do
    result = accumulate_tag(tail)

    case result do
      {:ok, %Tag{name: ""}, _tail} ->
        {:error, "Tags for partials require a name, e.g. {{>foo}}"}

      {:ok, tag, tail} ->
        partial = get_helper(helpers, tag.name)

        case partial do
          {:ok, callback} -> parse(resolve_partial(callback, tag.options) <> tail, acc, helpers)
          {:error, message} -> {:error, message}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  # Non-escaped tag
  defp parse("{{{" <> tail, acc, helpers) do
    result = accumulate_tag(tail, "}}}")
    # TODO: check to see if there is a helper registered! ???
    case result do
      {:ok, %Tag{name: ""}, _tail} -> {:error, "Escaped tags require a name, e.g. {{{foo}}}"}
      {:ok, tag, tail} -> parse(tail, acc <> "<%= #{tag.name} %>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Regular tag (HTML-escaped)
  defp parse("{{" <> tail, acc, helpers) do
    result = accumulate_tag(tail)
    # TODO: check to see if there is a helper registered!
    case result do
      {:ok, %Tag{name: ""}, _tail} ->
        {:error, "Non-escaped tags require a name, e.g. {{foo}}"}

      {:ok, tag, tail} ->
        parse(tail, acc <> "<%= HtmlEntities.encode(#{tag.name}) %>", helpers)

      {:error, message} ->
        {:error, message}
    end
  end

  # Error: ending delimiter found
  # Try to include some information in the error message
  defp parse("}}" <> tail, acc, _helpers) do
    cond do
      String.length(acc) > 32 ->
        <<first_chunk :: binary - size(32)>> <> _ = acc
        {:error, "Unexpected closing delimiter: }}#{first_chunk}"}

      true ->
        {:error, "Unexpected closing delimiter: }}"}
    end
  end

  defp parse(<<head :: binary - size(1)>> <> tail, acc, helpers),
       do: parse(tail, acc <> head, helpers)

  # This block is devoted to finding the tag and returning data about it (as a %Tag{} struct)
  @spec accumulate_tag(head, delimiter, accumulator) ::
          {:error, String.t()} | {:ok, %Tag{}, tail}
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

  defp accumulate_tag("{" <> tail, delimiter, tag_acc) do
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

  # TODO: namespaces for helpers vs. block-helpers vs. partials?
  @spec get_helper(map, String.t()) :: function()
  defp get_helper(helpers, partial) do
    case Map.has_key?(helpers, partial) do
      true -> {:ok, Map.get(helpers, partial)}
      false -> {:error, "Unregistered helper: #{partial}"}
    end
  end

  @spec resolve_partial(function, String.t()) :: String.t()
  defp resolve_partial(callback, options) when is_function(callback) do
    callback.(options)
  end

  @spec resolve_partial(String.t(), String.t()) :: String.t()
  defp resolve_partial(callback, options) when is_binary(callback) do
    callback
  end

  defp resolve_helper(callback, options) do
  end

  defp resolve_block(callback, options) do
  end

  # TODO?  Or just rely on Map.put() ? Better to use this function if the struct becomes more complex
  #  def register_helper(helpers, name, callback) do
  #    helpers
  #  end
end
