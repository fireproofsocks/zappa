defmodule Zappa.BlockHelpers.Unless do
  @moduledoc false
  # This module implements the `unless` block-helper.
  # https://handlebarsjs.com/guide/builtin-helpers.html#unless

  alias Zappa.Tag

  def parse(%Tag{raw_options: ""}) do
    {:error, "The unless helper requires options, e.g. {{#unless options}}"}
  end

  def parse(%Tag{else_contents: nil} = tag) do
    {:ok, "<%= unless Zappa.is_truthy?(#{tag.raw_options}) do %>#{tag.block_contents}<% end %>"}
  end

  def parse(%Tag{else_contents: else_contents} = tag) do
    {:ok,
     "<%= unless Zappa.is_truthy?(#{tag.raw_options}) do %>#{tag.block_contents}<% else %>#{
       else_contents
     }<% end %>"}
  end
end
