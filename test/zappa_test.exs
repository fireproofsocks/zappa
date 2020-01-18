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
    test "Unexpected closing delimiter" do
      tpl = "this is a bad}} string"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "Unexpected closing delimiter includes some info about where it was found" do
      tpl = "this is story of a bad, bad girl who never had the }} time"
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

    test "unexpected closing block not allowed out of the blue" do
      tpl = "this is {{/my-block}} no good"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "unexpected closing block not allowed within another block" do
      tpl = "{{#if z}}How about{{/dong-work}}{{/if}}"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "blocks must be closed" do
      tpl = "{{#if I}} opened a block tag and just wandered off?"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "block helper not registered" do
      tpl = "{{#dingus}} forgot to register{{/dingus}}"
      assert {:error, _} = Zappa.compile(tpl)
    end

    #    test "attempts to hijack" do
    #      tpl = "this is {{ derp IO.puts(\"Snark\") }} malicious"
    #      assert {:error, _} = Zappa.compile(tpl)
    #    end
  end

  describe "default helpers" do
    test "__escaped__ falls back to @default_escaped_callback when no function registered" do
      {:ok, "<%= Zappa.HtmlEncoder.encode(hot_rats) %>"} =
        Zappa.compile("{{hot_rats}}", %Zappa.Helpers{})
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

  describe "compile!/1" do
    test "errors are raised" do
      assert_raise RuntimeError, fn ->
        tpl = "this is a bad}} string"
        Zappa.compile!(tpl)
      end
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
        <h1><%= Zappa.HtmlEncoder.encode(title) %></h1>
        <div class="body">
          <%= Zappa.HtmlEncoder.encode(body) %>
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
        |> Zappa.register_helper("hello_x", fn tag -> {:ok, "Hello #{tag.raw_options}"} end)

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

      assert {:ok, "hello <%= Zappa.HtmlEncoder.encode(thing) %>"} = Zappa.compile(tpl, helpers)
    end

    test "partial string that has been registered is substituted in" do
      tpl = "{{> myPartial }}"

      helpers = Zappa.register_partial(%Helpers{}, "myPartial", "hello {{thing}}")

      assert {:ok, "hello <%= Zappa.HtmlEncoder.encode(thing) %>"} = Zappa.compile(tpl, helpers)
    end
  end

  describe "block {{#tags}}" do
    test "if: else statement" do
      tpl = "{{#if author}}<h1>{{name}}</h1>{{else}}<h1>Unknown Author</h1>{{/if}}"

      output =
        "<%= if author do %><h1><%= Zappa.HtmlEncoder.encode(name) %></h1><% else %><h1>Unknown Author</h1><% end %>"

      assert {:ok, output} == Zappa.compile(tpl)
    end

    test "if: statement requires options" do
      tpl = "{{#if}}<h1>{{name}}</h1>{{else}}<h1>Unknown Author</h1>{{/if}}"
      assert {:error, _} = Zappa.compile(tpl)
    end

    test "unless: else statement" do
      tpl = "{{#unless author}}<h1>Unknown Author</h1>{{else}}<h1>{{name}}</h1>{{/unless}}"

      output =
        "<%= unless author do %><h1>Unknown Author</h1><% else %><h1><%= Zappa.HtmlEncoder.encode(name) %></h1><% end %>"

      assert {:ok, output} == Zappa.compile(tpl)
    end
  end

  describe "register_block/3" do
    test "names cannot begin with periods" do
      assert_raise RuntimeError, fn ->
        Zappa.get_default_helpers()
        |> Zappa.register_block(".this", fn _ -> "boom" end)
      end
    end

    test "register block helper succeeds" do
      assert %Helpers{block_helpers: %{"x-out" => callback}} =
               Zappa.get_default_helpers()
               |> Zappa.register_block("x-out", fn _ -> "xxxxxx" end)

      assert is_function(callback)
    end
  end

  describe "register_helper/3" do
    test "raises error when name is not binary or atom" do
      assert_raise RuntimeError, fn -> Zappa.register_helper(%Helpers{}, %{}, "value") end
    end

    test "raises error when name begins with a period" do
      assert_raise RuntimeError, fn -> Zappa.register_helper(%Helpers{}, %{}, "value") end
    end

    test "override __escaped__" do
      helpers =
        Zappa.register_helper(%Helpers{}, "__escaped__", fn tag ->
          {:ok, "<%= my_encode(#{tag.name}) %>"}
        end)

      {:ok, result} = Zappa.compile("{{wet_tshirt}}", helpers)
      assert "<%= my_encode(wet_tshirt) %>" == result
    end

    test "override __unescaped__" do
      helpers =
        Zappa.register_helper(%Helpers{}, "__unescaped__", fn tag ->
          {:ok, "<%= my_raw(#{tag.name}) %>"}
        end)

      {:ok, result} = Zappa.compile("{{{dong_work}}}", helpers)
      assert "<%= my_raw(dong_work) %>" == result
    end

    test "regular operation" do
      result =
        Zappa.get_default_helpers()
        |> Zappa.register_helper("all_caps", fn options -> String.upcase(options) end)

      assert %Helpers{helpers: %{"all_caps" => _}} = result
    end
  end
end
