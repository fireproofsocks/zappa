defmodule Zappa do
  @moduledoc """
  Documentation for Zappa.
  """

  require Logger

  # Types to help make the the specs and function documentation more clear.
  @typedoc """
  A valid [Handlebars.js](https://handlebarsjs.com/) template (as a string). [Try it](http://tryhandlebarsjs.com/)!
  """
  @type handlebars_template :: String.t()

  @typep head :: String.t() # The string being parsed, from the active point to the end.
  @typep tail :: String.t() # The rest of the string
  @typep ending_delimiter :: String.t() # A string denoting the end of a tag
  @typep accumulator :: String.t()
  @typep tag_name :: String.t() # The name of a tag, e.g. `<a href="localhost">` --> `a`
  @typep tag_attributes :: String.t() # The attributes within tag, e.g. `<a href="localhost">` --> `href="localhost"`

  @doc """
  Evaluate the handlebars string and return the result. (The name is borrowed the name from EEx.eval_string)
  """
  @spec eval_string(handlebars_template, list) :: String.t
  def eval_string(handlebars_template, values_list) do
    handlebars2eex(handlebars_template)
    |> EEx.eval_string(values_list)
  end

  @spec eval_string(handlebars_template, list, map) :: String.t
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
  @spec handlebars2eex(handlebars_template) :: {:ok, String.t} | {:error, String.t}
  def handlebars2eex(template), do: handlebars2eex(template, get_default_helpers())

  @doc """
  Compiles a handlebars template to EEx using the helpers provided.

  """
  @spec handlebars2eex(handlebars_template, map) :: {:ok, String.t} | {:error, String.t}
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
  defp parse("", acc, _helpers), do: {:ok, acc}

  defp parse("{{!--" <> tail, acc, helpers) do
    result = get_tag_attributes(tail, "--}}")
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%##{tag_contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{!" <> tail, acc, helpers) do
    result = get_tag_attributes(tail)
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%##{tag_contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{#" <> tail, acc, helpers) do
    result = get_tag_attributes(tail)
    # Get name of block helper
    # seek the close of the block
    #    block_name = "if"
    #    helpers[block_name].()
  end

  defp parse("{{>" <> tail, acc, helpers) do
    result = get_tag_attributes(tail)
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
          true -> {:error, "Partial is unregistered or is not a string."}
        end
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{{" <> tail, acc, helpers) do
    result = get_tag_attributes(tail, "}}}")
    # TODO: check to see if there is a helper registered! ???
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%= #{tag_contents} %>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{" <> tail, acc, helpers) do
    result = get_tag_attributes(tail)
    # TODO: check to see if there is a helper registered!
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%= HtmlEntities.encode(#{tag_contents}) %>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  # Try to include some information in the error message
  defp parse("}}" <> tail, acc, _helpers)  do
    cond do
      String.length(acc) > 32 ->
        <<first_chunk :: binary - size(32)>> <> _ = acc
        {:error, "Unexpected closing tag: }}#{first_chunk}"}
      true -> {:error, "Unexpected closing tag: }}"}
    end
  end
  defp parse(<<head :: binary - size(1)>> <> tail, acc, helpers), do: parse(tail, acc <> head, helpers)

  # This block is devoted to finding the inside of the tag and returning its contents, i.e. its "attributes".
  # e.g. given "something here}} etc..."
  # then return {:ok, "something here", "etc..."}
  @spec get_tag_attributes(head, ending_delimiter, accumulator) :: {:error, String.t} | {:ok, accumulator, tail}
  defp get_tag_attributes(head, delimiter \\ "}}", tag_acc \\ "")
  defp get_tag_attributes("", _delimiter, _tag_acc), do: {:error, "Unclosed tag."}
  defp get_tag_attributes(<<h :: binary - size(4), tail :: binary>>, delimiter, tag_acc) when delimiter == h,
       do: separate_tag_name_from_attributes(tag_acc, tail)
#       do: {:ok, tag_acc, tail}
  defp get_tag_attributes(<<h :: binary - size(3), tail :: binary>>, delimiter, tag_acc) when delimiter == h,
       do: separate_tag_name_from_attributes(tag_acc, tail)
#       do: {:ok, tag_acc, tail}
  defp get_tag_attributes(<<h :: binary - size(2), tail :: binary>>, delimiter, tag_acc) when delimiter == h,
       do: separate_tag_name_from_attributes(tag_acc, tail)
#       do: {:ok, tag_acc, tail}
  defp get_tag_attributes("{" <> tail, delimiter, tag_acc),
       do: {:error, "Unexpected opening bracket inside a tag:{#{tail}"}
  defp get_tag_attributes(<<head :: binary - size(1)>> <> tail, delimiter, tag_acc),
       do: get_tag_attributes(tail, delimiter, tag_acc <> head)

  # https://elixirforum.com/t/how-to-detect-if-a-given-character-grapheme-is-whitespace/26735/5
  @spec separate_tag_name_from_attributes(accumulator, tail) :: {:error, String.t} | {:ok, tag_name, tag_attributes, tail}
  defp separate_tag_name_from_attributes(tag_acc, tail) do
    result = String.split(tag_acc, ~r/\p{Zs}/u, parts: 2)
    case result do
      [""] -> {:error, "Missing tag name"}
      ["", _] -> {:error, "Missing tag name"}
      [tag_name] -> {:ok, tag_name, "", tail}
      [tag_name, tag_attributes] -> {:ok, tag_name, String.trim(tag_attributes), tail}
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
