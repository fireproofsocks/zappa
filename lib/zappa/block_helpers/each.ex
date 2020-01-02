defmodule Zappa.BlockHelpers.Each do
  @moduledoc """
  This module implements the [each](https://handlebarsjs.com/guide/builtin-helpers.html#each) block-helper as
  demonstrated by Handlebars. It is one of the built-in block helpers.

  The `each` helper allows your template to iterate over a list or map. Although this "one-size-fits-all" approach makes
  more sense in Handlebars' native Javascript, but it is possible to obfuscate the internals in Elixir too.

  By default, the current item is available using the `{{this}}` tag, and like Handlebars, Zappa exposes a `{{@index}}`
  helper which will indicate the integer position in the list (zero-based). This is accomplished via a dedicated
  `@index` helper.  For feature parity with Handlebars, `{{else}}` blocks are also supported (via another dedicated
  helper).


  ## Handlebars Examples

  ```
  {{#each discography}}
    {{this}} was a hit!
  {{/each}}
  ```

  ### Using an `{{else}}` block:

  ```
  {{#each catholic_girls}}
    {{this}} in a little white dress!
  {{else}}
    There are no Catholic Girls.
  {{/each}}
  ```

  """

  #
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
