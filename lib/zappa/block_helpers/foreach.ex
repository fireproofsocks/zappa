defmodule Zappa.BlockHelpers.ForEach do
  @moduledoc false

  # This exists to enumerate a list (and only a list).  Unlike the `Zappa.BlockHelpers.ForEach` helper, this
  # does not attempt to work with maps.
  # This helper must include options.
  # See https://elixirforum.com/t/complex-loop-in-eex/27698/2

  alias Zappa.{OptionParser, Tag}

  # The name of the index variable should match up with the index helper.
  @index_var "index___helper"

  def parse(%Tag{args: []}) do
    {:error, "The foreach helper requires arguments, e.g. {{#foreach my_list}}"}
  end

  def parse(tag) do
    case OptionParser.split_block(tag.raw_options) do
      {:ok, {variable, iterator, index}} -> do_parse(tag, variable, iterator, index)
      {:error, msg} -> {:error, msg}
    end
  end

  def do_parse(tag, variable, iterator, index) do
    out = ~s"""
      <%= Enum.with_index(#{variable}) |> Enum.map(fn {#{iterator}, #{index}} -> %>
      <% #{@index_var} = #{index} %>
      <% Zappa.shutup(#{@index_var}) %>
      #{tag.block_contents}
    <% end) %>
    """

    {:ok, out}
  end
end
