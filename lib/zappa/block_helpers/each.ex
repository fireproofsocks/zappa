defmodule Zappa.BlockHelpers.Each do
  @moduledoc false

  #
  # This helper must include options.
  # See https://elixirforum.com/t/complex-loop-in-eex/27698/2

  alias Zappa.{OptionParser, Tag}

  # The name of the index variable should match up with the index helper.
  @index_var "index___helper"

  def parse(%Tag{args: []}) do
    {:error, "The each helper requires options, e.g. {{#each options}}"}
  end

  def parse(tag) do
    case OptionParser.split_block(tag.raw_options) do
      {:ok, {variable, iterator, index}} -> do_parse(tag, variable, iterator, index)
      {:error, msg} -> {:error, msg}
    end
  end

  def do_parse(tag, variable, iterator, index) do
    #    {var, iterator, index___helper} = OptionParser.block(tag.raw_options)
    #    IO.inspect(tag)
    #    %{quoted?: false, value: var} = List.first(tag.args)
    #    this = "this"
    # When operating on a map, Enum.with_index/1 returns a list of nested tuples:
    # iex> Enum.with_index(%{cat: "dog", foo: "bar"})
    # [{{:cat, "dog"}, 0}, {{:foo, "bar"}, 1}]

    # We have to initialize the helpers for some reason (WTF?)
    out = ~s"""
      <% index___helper = nil %>
      <% key___helper = nil %>
      <%= if Zappa.is_truthy?(#{variable}) do %>
        <%= Enum.with_index(#{variable}) |> Enum.map(fn({#{iterator}, #{index}}) -> %>
          <% #{@index_var} = #{index} %>
          <%= if is_tuple(#{iterator}) do %>
            <%# --- this block applies when the variable under enumeration is a map --- %>
            <% {key___helper, #{iterator}} = #{iterator} %>
            <% Zappa.shutup(index___helper) %>
            <% Zappa.shutup(key___helper) %>
            #{tag.block_contents}
          <% else %>
            <%# --- this block applies when the variable under enumeration is a list --- %>
            #{tag.block_contents}
          <% end %>
        <% end) %>
      <% else %>
        #{tag.else_contents}
      <% end %>
    """

    {:ok, out}
  end
end
