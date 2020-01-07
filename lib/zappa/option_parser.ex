defmodule Zappa.OptionParser do
  @moduledoc false

  @doc ~S"""
  This function is a lo-fi knock-off of the original
  [OptionParser.split/1](https://hexdocs.pm/elixir/1.3.4/OptionParser.html#split/1) tweaked specifically to support
  Handlebars [Hash Arguments](https://handlebarsjs.com/guide/block-helpers.html#hash-arguments).

  This function splits a raw string into a list of arguments and keyword arguments.  The arguments encountered are
  classified as being either quoted or unquoted so that downstream parsing can know whether to treat the value as a
  variable or as a string constant.

  The `split/1` function returns a tuple containing a list of value maps and a map containing the "hash arguments".

  ## Examples

      iex> Zappa.OptionParser.split("foo bar")


      iex> OptionParser.split("foo \"bar baz\"")

  """
  def split(string) when is_binary(string) do
    do_split(String.trim_leading(string, " "), "", [], "", %{}, nil, false)
  end

  # Did we find an equals sign?
  defp do_split("=" <> t, args_buffer, args_acc, _kwargs_buffer, kwargs_acc, nil, false) do
    do_split(String.trim_leading(t, " "), "", args_acc, args_buffer, kwargs_acc, nil, true)
  end

  # @spec do_split(argv_head, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote_marker, equals_marker)
  defp do_split(<<?\\, quote, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, equals),
       do: do_split(t, <<args_buffer :: binary, quote>>, args_acc, kwargs_buffer, kwargs_acc, quote, equals)

  # If we have a quote and we were not in a quote, start one
  defp do_split(<<quote, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, equals)
       when quote in [?", ?'] do
    do_split(t, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, equals)
  end

  # If we have a quote and we were inside it, close it
  #  defp do_split(<<quote, t::binary>>, args_buffer, args_acc, quote), do: do_split(t, args_buffer, args_acc, nil)
  defp do_split(<<quote, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, false) do
    do_split(
      String.trim_leading(t, " "),
      "",
      [%{value: args_buffer, quoted?: true} | args_acc],
      kwargs_buffer,
      kwargs_acc,
      nil,
      false
    )
  end

  # If we are in a key/value declaration and we end a quote, track the hash value and reset the buffers
  defp do_split(<<quote, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, true) do
    do_split(
      String.trim_leading(t, " "),
      "",
      args_acc,
      "",
      Map.put(kwargs_acc, String.to_atom(kwargs_buffer), args_buffer),
      nil,
      false
    )
  end

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_split(<<?\\, h, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, equals)
       when h in [?\s, ?', ?"] do
    do_split(t, <<args_buffer :: binary, h>>, args_acc, kwargs_buffer, kwargs_acc, nil, equals)
  end

  # If we have a space and we are outside of a quote, start new segment
  defp do_split(<<?\s, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, false) do
    do_split(
      String.trim_leading(t, " "),
      "",
      [%{value: args_buffer, quoted?: false} | args_acc],
      kwargs_buffer,
      kwargs_acc,
      nil,
      false
    )
  end

  # If we are in a key/value declaration and we find a space outside a quote, track the hash value and reset the buffers
  defp do_split(<<?\s, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, true) do
    do_split(
      String.trim_leading(t, " "),
      "",
      args_acc,
      "",
      Map.put(kwargs_acc, String.to_atom(kwargs_buffer), args_buffer),
      nil,
      false
    )
  end

  # All other characters are moved to args_buffer
  defp do_split(<<h, t :: binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, equals) do
    do_split(t, <<args_buffer :: binary, h>>, args_acc, kwargs_buffer, kwargs_acc, quote, equals)
  end

  # Finish the string expecting a nil marker
  defp do_split(<<>>, "", args_acc, _kwargs_buffer, kwargs_acc, nil, _equals), do: {Enum.reverse(args_acc), kwargs_acc}

  defp do_split(<<>>, args_buffer, args_acc, _kwargs_buffer, kwargs_acc, nil, false),
       do: {Enum.reverse([%{value: args_buffer, quoted?: false} | args_acc]), kwargs_acc}
  defp do_split(<<>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, true),
       do: {Enum.reverse(args_acc), Map.put(kwargs_acc, String.to_atom(kwargs_buffer), args_buffer)}

  # Otherwise raise
  defp do_split(<<>>, _, _args_acc, _kwargs_buffer, _kwargs_acc, marker, _equals) do
    raise "Tag options string did not terminate properly, a #{<<marker>>} was opened but never closed"
  end
end