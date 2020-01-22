defmodule Zappa.BlockHelpers.Raw do
  @moduledoc false
  # This module implements a simple "raw" helper, intended for use by the quadruple {{{{#raw}}}} ... {{{{/raw}}}} blocks
  # Raw block helpers should be used anytime the output must contain handlebars tags.
  alias Zappa.Tag

  def parse(%Tag{} = tag) do
    {:ok, tag.block_contents}
  end
end
