defmodule Zappa.BlockHelpers.Unless do
  @moduledoc false
  # This module implements the `unless` block-helper.
  # https://handlebarsjs.com/guide/builtin-helpers.html#unless

  alias Zappa.Tag

  def parse(%Tag{} = tag) do
    output = "<%= unless #{tag.raw_options} %>#{tag.parsed_block_contents}<% end %>"
    {:ok, output}
  end
end
