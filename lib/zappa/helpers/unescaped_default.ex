defmodule Zappa.Helpers.UnescapedDefault do
  @moduledoc false
  # This is the default helper used for escaped tags, e.g. `{{{tags}}}`.

  alias Zappa.Tag

  @spec parse(%Tag{}) :: {:ok, String.t()} | {:ok, String.t()}
  def parse(%Tag{raw_options: ""} = tag),
    do: {:ok, "<%= #{tag.name} %>"}

  @spec parse(%Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  def parse(_tag) do
    {:error, "Options not allowed for unescaped tags"}
  end
end
