defmodule Zappa.BlockHelpers.Unless do
  @moduledoc """
  This module implements the `unless` block-helper.
  https://handlebarsjs.com/guide/builtin-helpers.html#unless
  """

  alias Zappa.Tag

  def parse_unless(%Tag{} = tag) do
    output = "<%= unless #{tag.options} %>#{tag.block_contents}<% end %>"
    {:ok, output}
  end
end
