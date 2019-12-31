defmodule Zappa.BlockHelpers.Each do
  @moduledoc false
  #  This module implements the [each](https://handlebarsjs.com/guide/builtin-helpers.html#each) block-helper.
  #  This helper must include options.
  # See https://elixirforum.com/t/complex-loop-in-eex/27698/2

  alias Zappa.Tag

  # The name of the index variable should match up with the index helper.
  @index_var "index___helper"

  def parse_each(%Tag{options: ""}) do
    {:error, "The each helper requires options, e.g. {{#each options}}"}
  end

  def parse_each(tag) do
    # TODO: parse arguments, eg. each person as |p|
    var = tag.options
    this = "this"

    out = ~s"""
      <%= if (is_list(#{var}) && #{var} != []) || (is_map(#{var}) && #{var} != %{}) do %>
      <%= Enum.with_index(#{var}) |> Enum.map(fn({#{this}, #{@index_var}}) -> %>
        <%= if is_tuple(#{this}) do %>
          <% {#{this}, _v} = #{this} %>
          #{tag.block_contents}
        <% else %>
          #{tag.block_contents}
        <% end %>
      <% end) %>
      <% end %>
    """

    {:ok, out}
  end
end
