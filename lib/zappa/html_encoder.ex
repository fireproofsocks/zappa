defmodule Zappa.HtmlEncoder do
  @moduledoc false

  @doc """
  Encode HTML entities in input value so the output may be safely printed inside HTML.
  Adapted from https://github.com/martinsvalin/html_entities
  Customization was required to handle non-binary input.
  """
  @spec encode(String.t()) :: String.t()
  def encode(value) when is_binary(value) do
    for <<x <- value>>, into: "" do
      case x do
        ?' -> "&apos;"
        ?" -> "&quot;"
        ?& -> "&amp;"
        ?< -> "&lt;"
        ?> -> "&gt;"
        _ -> <<x>>
      end
    end
  end

  def encode(value) when is_map(value) do
    "[Map]"
  end

  def encode(value) when is_list(value) do
    "[List]"
  end

  # Handle numbers, booleans
  def encode(value) do
    to_string(value)
  end
end
