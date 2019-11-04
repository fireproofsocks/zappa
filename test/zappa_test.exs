defmodule ZappaTest do
  use ExUnit.Case
#  doctest Zappa

  # http://tryhandlebarsjs.com/

#  describe "handlebars2eex/1" do
#    test "something" do
#      template = "<p>{{ first }} {{last}}</p>"
#      values = [first: "Bog", last: "Man"]
#      assert "<p><%= HtmlEntities.encode(first) %> <%= HtmlEntities.encode(last) %></p>" == Zappa.parse(template, values)
#    end
#  end

  describe "handlebars2eex/1" do
    test "regular double braces" do
      tpl = ~s"""
<div class="entry">
  <h1>{{title}}</h1>
  <div class="body">
    {{body}}
  </div>
</div>
        """

      output = ~s"""
<div class="entry">
  <h1><%= title %></h1>
  <div class="body">
    <%= body %>
  </div>
</div>
  """
    end

    test "partials" do
      tpl = "{{> myPartial }}"
      # How to know which variables are in scope to pass them to the partial?
      output = ~s"""
<%= render("key.html", key: key) %>
    """
    end
  end

  describe "if-statements" do

    test "if-else-statement" do
      tpl = ~s"""
      <div class="entry">
        {{#if author}}
          <h1>{{firstName}} {{lastName}}</h1>
        {{else}}
          <h1>Unknown Author</h1>
        {{/if}}
      </div>
      """

      output = ~s"""
        <div class="entry">
          <%= if author %>
            <h1><%= firstName %> <%= lastName %></h1>
          <% else %>
            <h1>Unknown Author</h1>
          <% end %>
        </div>
      """
    end
  end

  describe "unless statement" do

  end

  describe "with statement" do

  end

  describe "each loop" do
    test "regular list" do
      tpl = ~s"""
      <ul class="people_list">
      {{#each people}}
      <li>{{this}}</li>
      {{/each}}
      </ul>
      """
      output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      </ul>
      """
    end

    test "list with as" do
      tpl = ~s"""
      <ul class="people_list">
      {{#each people}}
      <li>{{this}}</li>
      {{/each}}
      </ul>
      """
      output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      </ul>
      """
    end

    # https://stackoverflow.com/questions/39937948/loop-through-a-maps-key-value-pairs
    test "list with block parameters (value only)" do
      tpl = ~s"""
      <ul class="people_list">
      {{#each people as |p|}}
      <li>{{p}}</li>
      {{/each}}
      </ul>
      """
      output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      </ul>
      """
    end

    test "list with block parameters (using as)" do
      tpl = ~s"""
      <ul class="people_list">
      {{#each people as |value key|}}
      <li>{{key}}.{{value}}</li>
      {{/each}}
      </ul>
      """
      output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      </ul>
      """
    end

    test "list with else" do
      tpl = ~s"""
      <ul class="people_list">
      {{#each people}}
      <li>{{this}}</li>
      {{else}}
      <b>No people...</b>
      {{/each}}
      </ul>
      """
      output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      ?????
      </ul>
      """
    end
  end

  describe "dealing with arrays or maybe objects" do
    # https://stackoverflow.com/questions/28459493/iterate-over-list-in-embedded-elixir
    test "Enum.each that works with either a list or a map" do
      # Both of these work
      m = %{a: "apple", b: "boy", c: "cat"}
      m = ["apple", "boy", "cat"]
      Enum.each(m,
        fn x ->
          case x do
            x when is_tuple(x) ->
              {k, v} = x
              IO.puts("#{k}: #{v}")
            x -> IO.puts(x)
          end
      end)

      Enum.with_index(m) |> Enum.each(
        fn {x, index} ->
          case x do
            x when is_tuple(x) ->
              {k, v} = x
              IO.puts("#{k}: #{v} @index:#{index}")
            x -> IO.puts("#{x} @index:#{index}")
          end
        end)
    end
  end
  describe "@index" do
    # https://stackoverflow.com/questions/38841248/elixir-templates-looping-through-a-list-with-iterator-value
    # Enum.with_index
  end

  describe "parse_triple_braces/1" do
    test "x" do
      template = "<p>{{{ first }}} {{{last}}}</p>"
      values = [first: "Bog", last: "Man"]
      assert "<p><%= first %> <%= last %></p>" == Zappa.parse_triple_braces(template)
    end
  end

  # TODO:
  # if statement
  # unless statement
  # with statement
  # each loop
  # @index
  #
#  describe "parse/3" do
#    test "something" do
#      template = "<p>{{ first }} {{last}}</p>"
#      values = [first: "Bog", last: "Man"]
#      assert "<p>Bog Man</p>" == Zappa.parse(template, values)
#    end
#  end
end
