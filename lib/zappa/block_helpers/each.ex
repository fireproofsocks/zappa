defmodule Zappa.BlockHelpers.Each do
  @moduledoc false
  #  This module implements the [each](https://handlebarsjs.com/guide/builtin-helpers.html#each) block-helper.
  #  This helper must include options.

  alias Zappa.Tag

  def parse_each(%Tag{options: ""}) do
    {:error, "The each helper requires options, e.g. {{#each options}}"}
  end

  def parse_each(tag) do
    out = ~s"""
        <%= for this <- #{tag.options} do %>
          #{tag.block_contents}
        <% end %>
    """

    {:ok, out}
  end
end
