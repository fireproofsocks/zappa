defmodule Zappa.OptionParser do
  @moduledoc false

  # The name of the index variable should match up with the index helper.
  @index_var "index___helper"
  @valid_variable_name_regex ~r/^[a-zA-Z]{1}[a-zA-Z0-9_]+$/

  @typep variable :: String.t()
  @typep iterator :: String.t()
  @typep index :: String.t()

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
  @spec split(String.t()) :: {list, map}
  def split(string) when is_binary(string) do
    do_split(String.trim_leading(string, " "), "", [], "", %{}, nil, false)
  end

  # Did we find an equals sign?
  defp do_split("=" <> t, args_buffer, args_acc, _kwargs_buffer, kwargs_acc, nil, false) do
    do_split(String.trim_leading(t, " "), "", args_acc, args_buffer, kwargs_acc, nil, true)
  end

  # If we have a quote and we were not in a quote, start one
  defp do_split(
         <<quote, t::binary>>,
         args_buffer,
         args_acc,
         kwargs_buffer,
         kwargs_acc,
         nil,
         equals
       )
       when quote in [?", ?'] do
    do_split(t, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, equals)
  end

  # If we have a quote and we were inside it, close it
  #  defp do_split(<<quote, t::binary>>, args_buffer, args_acc, quote), do: do_split(t, args_buffer, args_acc, nil)
  defp do_split(
         <<quote, t::binary>>,
         args_buffer,
         args_acc,
         kwargs_buffer,
         kwargs_acc,
         quote,
         false
       ) do
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
  defp do_split(
         <<quote, t::binary>>,
         args_buffer,
         args_acc,
         kwargs_buffer,
         kwargs_acc,
         quote,
         true
       ) do
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
  # (I have no idea when someone would use this)
  defp do_split(
         <<?\\, h, t::binary>>,
         args_buffer,
         args_acc,
         kwargs_buffer,
         kwargs_acc,
         nil,
         equals
       )
       when h in [?\s, ?', ?"] do
    do_split(t, <<args_buffer::binary, h>>, args_acc, kwargs_buffer, kwargs_acc, nil, equals)
  end

  # If we have a space and we are outside of a quote, start new segment
  defp do_split(<<?\s, t::binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, false) do
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
  defp do_split(<<?\s, t::binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, true) do
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
  defp do_split(<<h, t::binary>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, quote, equals) do
    do_split(t, <<args_buffer::binary, h>>, args_acc, kwargs_buffer, kwargs_acc, quote, equals)
  end

  # Finish the string expecting a nil marker
  defp do_split(<<>>, "", args_acc, _kwargs_buffer, kwargs_acc, nil, _equals),
    do: {Enum.reverse(args_acc), kwargs_acc}

  defp do_split(<<>>, args_buffer, args_acc, _kwargs_buffer, kwargs_acc, nil, false),
    do: {Enum.reverse([%{value: args_buffer, quoted?: false} | args_acc]), kwargs_acc}

  defp do_split(<<>>, args_buffer, args_acc, kwargs_buffer, kwargs_acc, nil, true),
    do: {Enum.reverse(args_acc), Map.put(kwargs_acc, String.to_atom(kwargs_buffer), args_buffer)}

  # Otherwise raise
  defp do_split(<<>>, _, _args_acc, _kwargs_buffer, _kwargs_acc, marker, _equals) do
    raise "Tag options string did not terminate properly, a #{<<marker>>} was opened but never closed"
  end

  @doc """
  This function exists to parse the weird Ruby-esque "block" closures that are used by Handlebars to specify custom
  iterators and indexes in loops. For example, you might see something like:

  ```
  {{#each notes as |note|}}
    {{note}}
  {{/each}}
  ```

  This function takes a string (the `raw_options` from a `Zappa.Tag` struct) and determines the variable being
  enumerated, the iterator variable, and the index variable. The result is returned as a tuple packaged in the
  common `{:ok, {variable, iterator, index}}`.  If no customizations are specified, default values are returned.

  ## Examples
      iex> Zappa.OptionParser.block("notes")
      {:ok, {"notes", "this", "index___helper"}

      iex> Zappa.OptionParser.block("notes as |note|")
      {:ok, {"notes", "note", "index___helper"}

      iex> Zappa.OptionParser.block("notes as |note, scaleDegree|")
      {:ok, {"notes", "note", "scaleDegree"}

      iex> Zappa.OptionParser.block("notes as |note, scaleDegree|")
      {:ok, {"notes", "note", "scaleDegree"}

      iex> Zappa.OptionParser.block("$$$ for rich white men")
      {:error, "Invalid input"}
  """
  @spec split_block(String.t()) :: {:ok, {variable, iterator, index}} | {:error, String.t()}
  def split_block(string) when is_binary(string) do
    with {:ok, variable, tail} <- find_variable(string),
         :ok <- validate_variable_name(variable),
         {:ok, iterator, index} <- find_iterator_index(tail) do
      {:ok, {variable, iterator, index}}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  # Get the initial variable
  defp find_variable(string) do
    case String.split(String.trim(string), ~r/\p{Zs}/u, parts: 2) do
      [""] -> {:error, "Missing variable"}
      [variable] -> {:ok, variable, ""}
      [variable, tail] -> {:ok, variable, String.trim(tail)}
    end
  end

  defp find_iterator_index("") do
    {:ok, "this", @index_var}
  end

  defp find_iterator_index(string) do
    # Get the contents of the |block|
    with [_, block] <- Regex.run(~r/^as\p{Zs}+\|(.*)\|.*$/, string),
         {iterator, index} <- split_index_iterator(block),
         :ok <- validate_variable_name(iterator),
         :ok <- validate_variable_name(index) do
      {:ok, iterator, index}
    else
      nil -> {:error, "Invalid syntax"}
      {:error, msg} -> {:error, msg}
    end
  end

  # We return tuples for smoother flow within the with clauses
  @spec validate_variable_name(String.t()) :: :ok | {:error, String.t()}
  defp validate_variable_name(string) do
    case Regex.match?(@valid_variable_name_regex, string) do
      false -> {:error, "Invalid variable name"}
      true -> :ok
    end
  end

  defp split_index_iterator(string) do
    case String.split(string, ",") do
      [iterator] -> {String.trim(iterator), @index_var}
      [iterator, index] -> {String.trim(iterator), String.trim(index)}
      _ -> {:error, "Invalid |block| contents"}
    end
  end
end
