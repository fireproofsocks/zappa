defmodule Zappa do
  @moduledoc """
  Documentation for Zappa.
  """
  alias Zappa.Tag
  require Logger

  # Types to help make the the specs and function documentation more clear.
  @typedoc """
  A valid [Handlebars.js](https://handlebarsjs.com/) template (as a string). [Try it](http://tryhandlebarsjs.com/)!
  """
  @typep handlebars_template :: String.t()

  # The string being parsed, from the active point to the end.
  @typep head :: String.t()
  # The rest of the string
  @typep tail :: String.t()
  # A string denoting the end of a tag
  @typep ending_delimiter :: String.t()
  @typep accumulator :: String.t()
  # The name of a tag, e.g. `<a href="localhost">` --> `a`
  @typep tag_name :: String.t()
  # The attributes within tag, e.g. `<a href="localhost">` --> `href="localhost"`
  @typep tag_attributes :: String.t()

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
      "if" => &Zappa.BlockHelpers.If.parse_if/0
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
  @spec handlebars2eex(handlebars_template) :: {:ok, String.t()} | {:error, String.t()}
  def handlebars2eex(template), do: handlebars2eex(template, get_default_helpers())

  @doc """
  Compiles a handlebars template to EEx using the helpers provided.

  """
  @spec handlebars2eex(handlebars_template, map) :: {:ok, String.t()} | {:error, String.t()}
  def handlebars2eex(template, helpers) do
    template
    |> strip_eex()
    |> parse("", helpers)
  end

  # {{ regular tag (html escaped)
  # {{{ non-escaped tag
  # {{! comment
  # {{!-- comment --}}
  # {{> partial
  # {{# block
  # {{{{raw-helper}}}}
  @spec parse(String.t(), accumulator, map) :: {:ok, String.t()} | {:error, String.t()}
  defp parse("", acc, _helpers), do: {:ok, acc}

  # Comment tag
  defp parse("{{!--" <> tail, acc, helpers) do
    result = detect_tag(tail, "--}}")

    case result do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Comment tag
  defp parse("{{!" <> tail, acc, helpers) do
    result = detect_tag(tail)

    case result do
      {:ok, tag, tail} -> parse(tail, acc <> "<%##{tag.contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Block
  defp parse("{{#" <> tail, acc, helpers) do
    result = detect_tag(tail)
    # Get name of block helper
    # seek the close of the block
    #    block_name = "if"
    #    helpers[block_name].()
  end

  # Partial
  defp parse("{{>" <> tail, acc, helpers) do
    result = detect_tag(tail)
    # TODO: check the tag_contents to see if there's junk in there.
    # TODO: expect that partials are registered as a function (not a simple string)
    case result do
      {:ok, tag_contents, tail} ->
        partial = String.trim(tag_contents)

        cond do
          Map.has_key?(helpers, partial) && is_binary(Map.get(helpers, partial)) ->
            presult = parse(Map.get(helpers, partial), "", helpers)

            case presult do
              {:ok, parsed_partial} -> parse(tail, acc <> parsed_partial, helpers)
              {:error, message} -> {:error, message}
            end

          true ->
            {:error, "Partial is unregistered or is not a string."}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  # Non-escaped tag
  defp parse("{{{" <> tail, acc, helpers) do
    result = detect_tag(tail, "}}}")
    # TODO: check to see if there is a helper registered! ???
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%= #{tag_contents} %>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Regular tag (HTML-escaped)
  defp parse("{{" <> tail, acc, helpers) do
    result = detect_tag(tail)
    # TODO: check to see if there is a helper registered!
    case result do
      {:ok, tag_contents, tail} ->
        parse(tail, acc <> "<%= HtmlEntities.encode(#{tag_contents}) %>", helpers)

      {:error, message} ->
        {:error, message}
    end
  end

  # Try to include some information in the error message
  defp parse("}}" <> tail, acc, _helpers) do
    cond do
      String.length(acc) > 32 ->
        <<first_chunk::binary-size(32)>> <> _ = acc
        {:error, "Unexpected closing tag: }}#{first_chunk}"}

      true ->
        {:error, "Unexpected closing tag: }}"}
    end
  end

  defp parse(<<head::binary-size(1)>> <> tail, acc, helpers),
    do: parse(tail, acc <> head, helpers)

  # This block is devoted to finding the tag and returning data about it (as a %Tag{} struct)
  @spec detect_tag(head, ending_delimiter, accumulator) ::
          {:error, String.t()} | {:ok, %Tag{}, tail}
  defp detect_tag(head, delimiter \\ "}}", tag_acc \\ "")
  defp detect_tag("", _delimiter, _tag_acc), do: {:error, "Unclosed tag."}

  defp detect_tag(<<h::binary-size(4), tail::binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp detect_tag(<<h::binary-size(3), tail::binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp detect_tag(<<h::binary-size(2), tail::binary>>, delimiter, tag_acc)
       when delimiter == h do
    make_tag_struct(tag_acc, tail)
  end

  defp detect_tag("{" <> tail, delimiter, tag_acc) do
    {:error, "Unexpected opening bracket inside a tag:{#{tail}"}
  end

  defp detect_tag(<<head::binary-size(1)>> <> tail, delimiter, tag_acc) do
    detect_tag(tail, delimiter, tag_acc <> head)
  end

  # https://elixirforum.com/t/how-to-detect-if-a-given-character-grapheme-is-whitespace/26735/5
  @spec make_tag_struct(accumulator, tail) :: {:error, String.t()} | {:ok, %Tag{}, tail}
  defp make_tag_struct(tag_acc, tail) do
    result = String.split(tag_acc, ~r/\p{Zs}/u, parts: 2)

    case result do
      [""] ->
        {:error, "Missing tag name"}

      ["", _] ->
        {:error, "Missing tag name"}

      [tag_name] ->
        {:ok, %Tag{name: tag_name, attributes: "", contents: String.trim(tag_acc)}, tail}

      [tag_name, tag_attributes] ->
        {
          :ok,
          %Tag{
            name: tag_name,
            attributes: String.trim(tag_attributes),
            contents: String.trim(tag_acc)
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
end
