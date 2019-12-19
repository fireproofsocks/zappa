defmodule ZappaTest do
  use ExUnit.Case

  alias Zappa.Helpers

  #  doctest Zappa

  # http://tryhandlebarsjs.com/

  #  describe "compile/1" do
  #    test "something" do
  #      template = "<p>{{ first }} {{last}}</p>"
  #      values = [first: "Bog", last: "Man"]
  #      assert "<p><%= HtmlEntities.encode(first) %> <%= HtmlEntities.encode(last) %></p>" == Zappa.parse(template, values)
  #    end
  #  end
  describe "invalid syntax:" do
    test "closing tag precedes opening tag" do
      tpl = "this is a bad}} string"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "tags cannot appear inside one another" do
      tpl = "{{nested {{tags}}}} are no good"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "empty tags cause errors for partials" do
      tpl = "this is {{>}} no good"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "closing block not allowed" do
      tpl = "this is {{/my-block}} no good"
      assert {:error, _} = Zappa.compile(tpl)
    end

    #    test "attempts to hijack" do
    #      tpl = "this is {{ derp IO.puts(\"Snark\") }} malicious"
    #      assert {:error, _} = Zappa.compile(tpl)
    #    end
  end

  describe "compile/1" do
    test "do nothing when there are no tags" do
      input = ~s"""
      This is regular text with no handlebar tags in it at all
      """

      assert {:ok, output} = Zappa.compile(input)
      assert input == output
    end

    test "Any EEx tags are stripped from the input string" do
      tpl = ~s"""
      Some <%= evil %> stuff
      """

      output = ~s"""
      Some  stuff
      """

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "regular double braces (html escaped)" do
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
        <h1><%= HtmlEntities.encode(title) %></h1>
        <div class="body">
          <%= HtmlEntities.encode(body) %>
        </div>
      </div>
      """

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "triple braces (unescaped)" do
      tpl = ~s"""
      <div class="entry">
        <h1>{{{title}}}</h1>
        <div class="body">
          {{{body}}}
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

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "triple braces (unescaped) tags do not allow options" do
      tpl = ~s"""
        <h1>{{{title should "not" include "options"}}}</h1>
      """

      assert {:error, _} = Zappa.compile(tpl)
    end

    test "partial that has not been registered triggers error" do
      tpl = "{{> myPartial }}"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "partial string that has been registered is substituted in" do
      tpl = "{{> myPartial }}"

      helpers =
        Zappa.register_partial(%Helpers{}, "myPartial", {:ok, "hello {{thing}}"})

#        assert true = Zappa.compile(tpl, helpers)
      assert {:ok, "hello <%= HtmlEntities.encode(thing) %>"} = Zappa.compile(tpl, helpers)
    end

    test "partial callback that has been registered is substituted in and its tags parsed" do
      tpl = "{{> myPartial }}"

      helpers =
        Zappa.register_partial(%Helpers{}, "myPartial", fn _tag -> {:ok, "hello {{thing}}"} end)

      assert {:ok, "hello <%= HtmlEntities.encode(thing) %>"} = Zappa.compile(tpl, helpers)
    end

    test "comments with short tags" do
      tpl = ~s"""
      <div class="entry">
        {{! This is a comment }}
      </div>
      """

      output = ~s"""
      <div class="entry">
        <%# This is a comment %>
      </div>
      """

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "comments with long tags" do
      tpl = ~s"""
      <div class="entry">
        {{!-- This is a comment --}}
      </div>
      """

      output = ~s"""
      <div class="entry">
        <%# This is a comment %>
      </div>
      """

      assert {:ok, output} == Zappa.compile(tpl)
    end
  end

  describe "if-statements" do
    @tag :skip
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
    @tag :skip
    test "something with" do
      tpl = ~s"""
      <div class="entry">
      {{#with story}}
        <div class="intro">{{intro}}</div>
        <div class="body">{{body}}</div>
      {{/with}}
      </div>
      """

      # ????? problems with atom vs string keys?
      output = ~s"""
        <div class="entry">
          <div class="intro"><%= story["intro"] %></div>
          <div class="body"><%= story["body"] %></div>
      </div>
      """
    end
  end

  describe "each loop" do
    @tag :skip
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

    @tag :skip
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
    @tag :skip
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

    @tag :skip
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

    @tag :skip
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
    @tag :skip
    test "Enum.each that works with either a list or a map" do
      # Both of these work
      m = %{a: "apple", b: "boy", c: "cat"}
      m = ["apple", "boy", "cat"]

      Enum.each(
        m,
        fn x ->
          case x do
            x when is_tuple(x) ->
              {k, v} = x
              IO.puts("#{k}: #{v}")

            x ->
              IO.puts(x)
          end
        end
      )

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
  end

  describe "@index" do
    # https://stackoverflow.com/questions/38841248/elixir-templates-looping-through-a-list-with-iterator-value
    # Enum.with_index
  end

  describe "default helper functions" do
    test "else helper" do
      tpl = ~s"""
      <div class="entry">
        {{else}}
      </div>
      """

      output = ~s"""
      <div class="entry">
        <% else %>
      </div>
      """

      assert {:ok, output} == Zappa.compile(tpl)
    end
  end

  describe "register_helper/3" do
    test "raises error when name is not binary or atom" do
    end

    test "regular " do
      result =
        Zappa.get_default_helpers()
        |> Zappa.register_helper("all_caps", fn options -> String.upcase(options) end)

      assert %Helpers{helpers: %{"all_caps" => _}} = result
    end
  end
end
