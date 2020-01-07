defmodule Zappa.Helpers.EscapedDefault do
  @moduledoc false
  # This is the default helper used for escaped tags, used to render simple `{{tags}}`.

  alias Zappa.Tag

  @spec parse(%Tag{}) :: {:ok, String.t()} | {:ok, String.t()}
  def parse(%Tag{raw_options: ""} = tag),
    do: {:ok, "<%= HtmlEntities.encode(#{tag.name}) %>"}

  @spec parse(%Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  def parse(_tag) do
    {:error, "Options not allowed for regular tags unless a helper is registered"}
  end
end
