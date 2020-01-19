defmodule Zappa.BlockHelpers.Raw do
  @moduledoc false
  # This module implements a simple "raw" helper, intended for use by the quadruple {{{{#raw}}}} ... {{{{/raw}}}} blocks

  alias Zappa.Tag

  def parse(tag) do
    {:ok, tag.block_contents}
  end
end
