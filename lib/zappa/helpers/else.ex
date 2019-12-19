defmodule Zappa.Helpers.Else do
  @moduledoc """
  This module implements the `else` helper function. This clause may be used inside of block-helpers.
  """

  # if options is not empty... error?
  def parse_else(_options) do
    {:ok, "<% else %>"}
  end
end
