defmodule Zappa.Helpers do
  @moduledoc """
  Helper functions
  """

  @doc """
  Desired output:
  <%= if your_variable %>
    HTML
  <% else %>

  <% end %>
  """
  def if(opening_tag_contents, block_contents, full_block) do
    regex = ~r/{{\s?else\s?}}/U
    block_contents = String.replace(block_contents, regex, "<% else %>")
    # on all blocks, down the wormhole...
    # Content might be something like
    # "something {{else}} beta beta"
    # But also, it might represent nested blocks
    # "something {{#if something}}True{{else}}False{{/if}} {{else}} beta beta"
    block_contents = Zappa.handlebars2eex(block_contents)
    # TODO: do we need to sanitize the opening_tag_contents to only allow a simple variable?
    eex_replacement = """
      <%= if #{opening_tag_contents} %>
      #{block_contents}
      <% end %>
    """

    #    String.replace()
  end

  def replace_else(content) do
    regex = ~r/{{\s?else\s?}}/U
    String.replace(content, regex, "<% else %>")
  end

  @doc """

  """
  def list(template, opening_tag_contents, block_contents, full_block) do
  end

  @doc """
  https://stackoverflow.com/questions/28459493/iterate-over-list-in-embedded-elixir
  <%= Enum.map(@list, fun(item) -> %>
  <p><%= item %></p>
  <% end) %>
  """
  def xlist() do
    m = %{a: "apple"}

    Enum.with_index(m)
    |> Enum.each(fn {x, index} ->
      case x do
        x when is_tuple(x) ->
          {k, v} = x
          IO.puts("#{k}: #{v} @index:#{index}")

        x ->
          IO.puts("#{x} @index:#{index}")
      end
    end)
  end

  @doc """
  This isn't a standard Handlebars feature, but it's so useful I included it here.
  """
  def join() do
  end

  @doc """

  """
  def unless() do
  end

  @doc """

  """
  def with() do
  end
end
