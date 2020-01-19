defmodule Zappa.BlockHelpers.If do
  @moduledoc false
  # This module implements the [if](https://handlebarsjs.com/guide/builtin-helpers.html#if) block-helper.
  # This helper must include options.

  alias Zappa.Tag

  def parse(%Tag{raw_options: ""}) do
    {:error, "The if helper requires options, e.g. {{#if options}}"}
  end

  def parse(tag) do
    {:ok, "<%= if #{tag.raw_options} do %>#{tag.block_contents}<% end %>"}
  end
end
