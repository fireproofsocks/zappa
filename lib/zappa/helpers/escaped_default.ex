defmodule Zappa.Helpers.EscapedDefault do
  @moduledoc false
  # This is the default helper used for escaped tags, used to render simple `{{tags}}`.

  alias Zappa.Tag

  @spec parse_escaped_default(%Tag{}) :: {:ok, String.t()} | {:ok, String.t()}
  def parse_escaped_default(%Tag{options: ""} = tag),
    do: {:ok, "<%= HtmlEntities.encode(#{tag.name}) %>"}

  @spec parse_escaped_default(%Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  def parse_escaped_default(_tag) do
    {:error, "Options not allowed for regular tags unless a helper is registered"}
  end
end
