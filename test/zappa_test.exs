defmodule ZappaTest do
  use Zappa.TestCase

  #  alias Zappa.Helpers

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

    test "unexpected closing block not allowed" do
      tpl = "this is {{/my-block}} no good"
      assert {:error, _} = Zappa.compile(tpl)
    end

    #    test "attempts to hijack" do
    #      tpl = "this is {{ derp IO.puts(\"Snark\") }} malicious"
    #      assert {:error, _} = Zappa.compile(tpl)
    #    end
  end

  describe "default helpers" do
    test "__escaped__ falls back to @default_escaped_callback when no function registered" do
        {:ok, "<%= HtmlEntities.encode(hot_rats) %>"} = Zappa.compile("{{hot_rats}}", %Zappa.Helpers{})
    end

    test "__unescaped__ falls back to @default_unescaped_callback when no function registered" do
      {:ok, "<%= plook %>"} = Zappa.compile("{{{plook}}}", %Zappa.Helpers{})
    end
  end

  describe "compile/1" do
    test "do nothing when there are no tags" do
      input = ~s"""
      This is regular text with no handlebar tags in it at all
      """

      assert {:ok, output} = Zappa.compile(input)
      assert input == output
    end

    test "error is returned if EEx expressions are detected" do
      tpl = ~s"""
      Some <%= evil %> stuff
      """
      assert {:error, _error} = Zappa.compile(tpl)
    end
  end

  describe "regular {{tags}}" do
    test "multiple tags get parsed" do
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

    test "regular tags should not allow tag options (when no helper is registered)" do
      tpl = "<h1>{{title options not allowed}}</h1>"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "helper functions do allow options" do
      tpl = "<h1>{{hello_x world}}</h1>"

      helpers =
        Zappa.get_default_helpers()
        |> Zappa.register_helper("hello_x", fn tag -> {:ok, "Hello #{tag.options}"} end)

      output = "<h1>Hello world</h1>"

      assert {:ok, output} == Zappa.compile(tpl, helpers)
    end

    test "helper functions may return a simple string" do
      tpl = "<h1>{{my_func}}</h1>"

      helpers =
        Zappa.get_default_helpers()
        |> Zappa.register_helper("my_func", fn _tag -> "Hello world" end)

      assert {:ok, "<h1>Hello world</h1>"} == Zappa.compile(tpl, helpers)
    end

    test "built-in else helper" do
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

    test "built-in else helper does not allow options" do
      tpl = ~s"""
      <div class="entry">
        {{else options not allowed}}
      </div>
      """

      assert {:error, _} = Zappa.compile(tpl)
    end

    test "built-in log helper" do
      tpl = ~s({{log "something happened"}})
      output = ~s(<% Logger.info\("something happened"\) %>)
      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "built-in log helper requires options" do
      tpl = ~s({{log}})
      assert {:error, _} = Zappa.compile(tpl)
    end
  end

  describe "non-escaped {{{tags}}" do
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
  end

  describe "comment {{!tags}}" do
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

  describe "partial {{>tags}}" do
    test "partial that has not been registered triggers error" do
      tpl = "{{> myPartial }}"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "partial callback that has been registered is substituted in and its tags parsed" do
      tpl = "{{> myPartial }}"

      helpers =
        Zappa.register_partial(%Helpers{}, "myPartial", fn _tag -> {:ok, "hello {{thing}}"} end)

      assert {:ok, "hello <%= HtmlEntities.encode(thing) %>"} = Zappa.compile(tpl, helpers)
    end

    test "partial string that has been registered is substituted in" do
      tpl = "{{> myPartial }}"

      helpers = Zappa.register_partial(%Helpers{}, "myPartial", "hello {{thing}}")

      assert {:ok, "hello <%= HtmlEntities.encode(thing) %>"} = Zappa.compile(tpl, helpers)
    end
  end

  describe "block {{#tags}}" do
    test "if: else statement" do
      tpl = "{{#if author}}<h1>{{name}}</h1>{{else}}<h1>Unknown Author</h1>{{/if}}"

      output =
        "<%= if author %><h1><%= HtmlEntities.encode(name) %></h1><% else %><h1>Unknown Author</h1><% end %>"

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "if: statement requires options" do
      tpl = "{{#if}}<h1>{{name}}</h1>{{else}}<h1>Unknown Author</h1>{{/if}}"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "unless: else statement" do
      tpl = "{{#unless author}}<h1>Unknown Author</h1>{{else}}<h1>{{name}}</h1>{{/unless}}"

      output =
        "<%= unless author %><h1>Unknown Author</h1><% else %><h1><%= HtmlEntities.encode(name) %></h1><% end %>"

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "each: regular list" do
      tpl = ~s"""
      <ul class="people_list">
      {{#each people}}
      <li>{{this}}</li>
      {{/each}}
      </ul>
      """

      expected = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= HtmlEntities.encode(this) %></li>
      <% end %>
      </ul>
      """

      {:ok, actual} = Zappa.compile(tpl)

      actual = strip_whitespace(actual)
      expected = strip_whitespace(expected)

      assert actual == expected
    end
  end

  describe "each loop" do
    # https://stackoverflow.com/questions/39937948/loop-through-a-maps-key-value-pairs
    @tag :skip
    test "list with block parameters (value only)" do
      _tpl = ~s"""
      <ul class="people_list">
      {{#each people as |p|}}
      <li>{{p}}</li>
      {{/each}}
      </ul>
      """

      _output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      </ul>
      """
    end

    @tag :skip
    test "list with block parameters (using as)" do
      _tpl = ~s"""
      <ul class="people_list">
      {{#each people as |value key|}}
      <li>{{key}}.{{value}}</li>
      {{/each}}
      </ul>
      """

      _output = ~s"""
      <ul class="people_list">
      <%= for this <- people do %>
      <li><%= this %></li>
      <% end %>
      </ul>
      """
    end

    @tag :skip
    test "list with else" do
      _tpl = ~s"""
      <ul class="people_list">
      {{#each people}}
      <li>{{this}}</li>
      {{else}}
      <b>No people...</b>
      {{/each}}
      </ul>
      """

      _output = ~s"""
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
      _m = %{a: "apple", b: "boy", c: "cat"}
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
