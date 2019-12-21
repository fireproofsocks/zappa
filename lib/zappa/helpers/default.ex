defmodule Zappa.Helpers.Default do
  @moduledoc false
  # This is the default helper, used to render simple `{{tags}}`.

  alias Zappa.Tag

  @spec parse_default(%Tag{}) :: {:ok, String.t()} | {:ok, String.t()}
  def parse_default(%Tag{options: ""} = tag),
    do: {:ok, "<%= HtmlEntities.encode(#{tag.name}) %>"}

  @spec parse_default(%Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  def parse_default(tag) do
    {:error, "Options not allowed for regular tags unless a helper is registered"}
  end
end
