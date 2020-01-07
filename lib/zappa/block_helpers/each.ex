defmodule Zappa.BlockHelpers.Each do
  @moduledoc false

  #
  #  This helper must include options.
  # See https://elixirforum.com/t/complex-loop-in-eex/27698/2

  alias Zappa.Tag

  # The name of the index variable should match up with the index helper.
  @index_var "index___helper"

  def parse(%Tag{args: []}) do
    {:error, "The each helper requires options, e.g. {{#each options}}"}
  end

  def parse(tag) do
    # TODO: parse arguments, eg. each person as |p|
    var = tag.raw_options
    this = "this"

    # We have to initialize the helpers for some reason (WTF?)
    out = ~s"""
      <% index___helper = nil %>
      <% key___helper = nil %>
      <%= if (is_list(#{var}) && #{var} != []) || (is_map(#{var}) && #{var} != %{}) do %>
      <%= Enum.with_index(#{var}) |> Enum.map(fn({#{this}, #{@index_var}}) -> %>
        <%= if is_tuple(#{this}) do %>
          <% {key___helper, #{this}} = #{this} %>
          <% Zappa.nothing(index___helper) %>
          <% Zappa.nothing(key___helper) %>
          #{tag.parsed_block_contents}
        <% else %>
          #{tag.parsed_block_contents}
        <% end %>
      <% end) %>
      <% end %>
    """

    {:ok, out}
  end

  @doc """
  Takes a string used in an each block tag and determines the variables to be used for the iterator and index.
  """
  def split(string) when is_binary(string) do
    
  end
end
