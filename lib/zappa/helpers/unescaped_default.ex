defmodule Zappa.Helpers.UnescapedDefault do
  @moduledoc false
  # This is the default helper used for escaped tags, e.g. `{{{tags}}}`.

  alias Zappa.Tag

  @spec parse_unescaped_default(%Tag{}) :: {:ok, String.t()} | {:ok, String.t()}
  def parse_unescaped_default(%Tag{options: ""} = tag),
    do: {:ok, "<%= #{tag.name} %>"}

  @spec parse_unescaped_default(%Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  def parse_unescaped_default(_tag) do
    {:error, "Options not allowed for unescaped tags"}
  end
end
