defmodule Zappa do
  @moduledoc """
  Documentation for Zappa.
  """

  require Logger

  @doc """
  Evaluate the handlebars string (the name is borrowed the name from EEx.eval_string)
  """
  @spec eval_string(String.t, list) :: String.t
  def eval_string(handlebars_template, values_list) do
    handlebars2eex(handlebars_template)
    |> EEx.eval_string(values_list)
  end

  @doc """
  Compiles a handlebars template to EEx


  ## Examples

      iex> Zappa.handlebars2eex()
      :world

  """
  @spec handlebars2eex(String.t, map) :: {:ok, String.t} | {:error, String.t}
  def handlebars2eex(template, helpers \\ %{}) do
    # Blocks... for each block |> parse (#each, #noop, other registered helpers)
    # Helpers (if, unless, with)
    # Regular tags (inside a block)
    template
    |> strip_eex()
    |> parse("", helpers)
  end

  #  def handlebars2eex(template, partials \\ %{}) do
  #
  #  end
  #
  #  def handlebars2eex(template, partials \\ %{}, helpers \\ %{}) do
  #    # register default helpers
  #  end

  # Main parsing function -- this can get called recursively
  #  def parse(template) do
  #    template
  #    # raw-helper?
  #    # partials?
  #    # |> parse_comments()
  #    # |> parse_triple_braces()
  #    # |> parse_double_braces()
  #  end

  # {{ regular tag (html escaped)
  # {{{ non-escaped tag
  # {{! comment
  # {{!-- comment --}}
  # {{> partial
  # {{# block
  defp parse("", acc, _helpers), do: {:ok, acc}

  defp parse("{{!--" <> tail, acc, helpers) do
    result = seek_tag_end(tail, "--}}")
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%##{tag_contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{!" <> tail, acc, helpers) do
    result = seek_tag_end(tail)
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%##{tag_contents}%>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{>" <> tail, acc, helpers) do
    result = seek_tag_end(tail)
    # TODO: check the tag_contents to see if there's junk in there.
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
    result = seek_tag_end(tail, "}}}")
    # TODO: check the tag_contents to see if there's junk in there.
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%= #{tag_contents} %>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("{{" <> tail, acc, helpers) do
    result = seek_tag_end(tail)
    # TODO: check the tag_contents to see if there's junk in there.
    case result do
      {:ok, tag_contents, tail} -> parse(tail, acc <> "<%= HtmlEntities.encode(#{tag_contents}) %>", helpers)
      {:error, message} -> {:error, message}
    end
  end

  defp parse("}}" <> tail, acc, _helpers)  do
    cond do
      String.length(acc) > 32 ->
        <<first_chunk :: binary - size(32)>> <> _ = acc
        {:error, "Unexpected closing tag: }}#{first_chunk}"}
      true -> {:error, "Unexpected closing tag: }}"}
    end
  end
  defp parse(<<head :: binary - size(1)>> <> tail, acc, helpers), do: parse(tail, acc <> head, helpers)

  @spec seek_tag_end(String.t, String.t, String.t) :: {:error, String.t} | {:ok, String.t, String.t}
  defp seek_tag_end(content, delimiter \\ "}}", tag_acc \\ "")
  defp seek_tag_end("", _delimiter, _tag_acc), do: {:error, "Unclosed tag."}
#  defp seek_tag_end("}}" <> tail, tag_acc), do: {:ok, tag_acc, tail}
  defp seek_tag_end(<<h :: binary-size(4), tail :: binary>>, delimiter, tag_acc) when delimiter == h, do: {:ok, tag_acc, tail}
  defp seek_tag_end(<<h :: binary-size(3), tail :: binary>>, delimiter, tag_acc) when delimiter == h, do: {:ok, tag_acc, tail}
  defp seek_tag_end(<<h :: binary-size(2), tail :: binary>>, delimiter, tag_acc) when delimiter == h, do: {:ok, tag_acc, tail}
  defp seek_tag_end("{" <> tail, delimiter, tag_acc), do: {:error, "Unexpected opening bracket inside a tag:{#{tail}"}
  defp seek_tag_end(<<head :: binary - size(1)>> <> tail, delimiter, tag_acc),
       do: seek_tag_end(tail, delimiter, tag_acc <> head)

  # Matching Closing tag found! --> return whatever is left of the string
  #  defp seek_end(closing_delimiter, <<h :: binary - size(1), tail :: binary>>) when closing_delimiter == h, do: tail

  @doc """
  This removes all EEX tags from the input template.
  This is a security measure in case some nefarious user gets the sneaky idea to put EEX functions inside what should
  be a Handlebars template.
  """
  def strip_eex(template) do
    regex = ~r/<%.*%>/U
    Regex.scan(regex, template)
    |> Enum.reduce(template, fn [x | _], acc -> String.replace(acc, x, "") end)
  end

end
