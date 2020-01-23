defmodule Zappa.Helpers.Comment do
  @moduledoc false
  # This module implements comments

  alias Zappa.Tag

  def parse(%Tag{} = tag) do
    {:ok, "<%##{tag.raw_contents}%>"}
  end
end
