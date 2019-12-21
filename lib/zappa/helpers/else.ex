defmodule Zappa.Helpers.Else do
  @moduledoc false
  # This module implements the `else` helper function. This clause may be used inside of block-helpers.

  alias Zappa.Tag

  def parse_else(%Tag{options: ""}) do
    {:ok, "<% else %>"}
  end

  def parse_else(_tag) do
    {:error, "{{else}} tag does not allow options."}
  end
end
