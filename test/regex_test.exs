defmodule Zappa.RegexTest do
  @moduledoc """
  My studies for figuring out Elixir regexes...
  """
  use ExUnit.Case

  describe "single tags" do
    # https://hexdocs.pm/elixir/String.html#replace/4
    test "basic find and replace" do
      assert "<p>Bob</p>" == String.replace("<p>{{name}}</p>", "{{name}}", "Bob")
    end

    test "find and replace with regex" do
      regex = ~r/{{\s*name\s*}}/
      assert "<p>Bob</p>" == String.replace("<p>{{name}}</p>", regex, "Bob")
      assert "<p>Bob</p>" == String.replace("<p>{{ name }}</p>", regex, "Bob")
    end

    test "html escaping" do
      value = "All about <b>Tags</b>"
      regex = ~r/{{\s*subject\s*}}/
      assert "<p>All about &lt;b&gt;Tags&lt;/b&gt;</p>" == String.replace("<p>{{subject}}</p>", regex,  HtmlEntities.encode(value))
    end

    test "triple braces for no escaping" do
      value = "All about <b>Tags</b>"
      regex = ~r/{{{\s*subject\s*}}}/
      assert "<p>All about <b>Tags</b></p>" == String.replace("<p>{{{subject}}}</p>", regex, value)
    end

    test "triple braces with variable name" do
      tpl = "All about <b>{{{tags}}}</b>"
      regex = ~r/{{{\s*(\p{L}*)\s*}}}/u
      assert [["{{{tags}}}", "tags"]] == Regex.scan(regex, tpl)
    end

    test "comments" do
      tpl = "All about <b>{{! pretty much anything at all in here }}</b>"
      regex = ~r/{{!(.*)}}/u
      assert true == Regex.scan(regex, tpl)
    end
  end


  describe "finding all tag names" do
    test "as list" do
      tpl = "<p>{{ first }} {{last}}</p>"
      assert [["{{ first }}", "first"], ["{{last}}", "last"]] == Regex.scan(~r/{{\s*(\p{L}*)\s*}}/u, tpl)
    end

    test "mixed escaped and non-escaped" do
      tpl = "<p>{{ double }} {{{triple}}}</p>"
      # match 2 or 3 braces per side
      regex = ~r/\{{2,3}\s*(\p{L}*)\s*\}{2,3}/u
      assert [["{{ double }}", "double"], ["{{{triple}}}", "triple"]] == Regex.scan(regex, tpl)
    end

#    test "lopsided?" do
#      tpl = "<p>{{{ whoops }}</p>"
#      # match 2 or 3 braces per side
#      regex = ~r/\{{2,3}\s*(\p{L}*)\s*\}{2,3}/u
#      assert [["{{ double }}", "double"], ["{{{triple}}}", "triple"]] == Regex.scan(regex, tpl)
#    end
  end

  describe "block-level tags" do
    test "discovering dotall (s)" do
      tpl = """
      junk junk
          start
            treasure!
          end
      junk junk
      """

      # We need the "dotall (s)" modifier here so that the .* can match everything between the start and finish
      regex = ~r/start(.*)end/us
      assert [["start\n      treasure!\n    end", "\n      treasure!\n    "]] == Regex.scan(regex, tpl)
    end

    test "matching the start of the block to the end with the name of the block" do
      tpl = """
    {{#list people}}
        <li>{{firstName}} {{lastName}}</li>
{{/list}}
"""
      regex = ~r/{{\#(\p{L}{1,})\s{1,}(\p{L}{1,})}}(.*){{\/(\p{L}{1,})}}/us
      result = Regex.scan(regex, tpl)
      [result | _] = result
      [full_match, opening_block_tag, var_name, inner_tpl, closing_block_tag] = result

      assert "{{#list people}}\n        <li>{{firstName}} {{lastName}}</li>\n{{/list}}" == full_match
      assert "list" == opening_block_tag
      assert "people" == var_name
      assert "\n        <li>{{firstName}} {{lastName}}</li>\n" == inner_tpl
      assert "list" == closing_block_tag
    end

    test "backreference proof of concept" do
      tpl = "something #block inner stuff /block something"
      regex = ~r/\#(\p{L}{1,})(.*)\/(\1)/us
      result = Regex.scan(regex, tpl)
      assert [["#block inner stuff /block", "block", " inner stuff ", "block"]] = result
    end

    test "use backreference to properly ensure that we match the full block" do
      tpl = """
          {{#list people}}
              <li>{{firstName}} {{lastName}}</li>
      {{/list}}
      """
      # Ta-da! The regex that properly matches blocks using the \1 backreference
      # See https://www.regular-expressions.info/backref.html
      regex = ~r/{{\#(\p{L}{1,})\s{1,}(\p{L}{1,})}}(.*){{\/\1}}/us
      result = Regex.scan(regex, tpl)

      [result | _] = result
      [full_match, opening_block_tag, var_name, inner_tpl] = result

      assert "{{#list people}}\n        <li>{{firstName}} {{lastName}}</li>\n{{/list}}" == full_match
      assert "list" == opening_block_tag
      assert "people" == var_name
      assert "\n        <li>{{firstName}} {{lastName}}</li>\n" == inner_tpl
    end

    test "match multiple blocks" do
      tpl = """
        {{#if something}}
          <bold>It's true!</bold>
        {{/if}}
          {{#list people}}
              <li>{{firstName}} {{lastName}}</li>
      {{/list}}
      """
      # This regex is exactly the same as above -- we just need to do recursion on the results
      regex = ~r/{{\#(\p{L}{1,})\s{1,}(\p{L}{1,})}}(.*){{\/\1}}/us
      result = Regex.scan(regex, tpl)

      [first_result | result] = result
      [second_result | _] = result

      [full_match, opening_block_tag, var_name, inner_tpl] = first_result

      assert "{{#if something}}\n    <bold>It's true!</bold>\n  {{/if}}" == full_match
      assert "if" == opening_block_tag
      assert "something" == var_name
      assert "\n    <bold>It's true!</bold>\n  " == inner_tpl

      [full_match, opening_block_tag, var_name, inner_tpl] = second_result

      assert "{{#list people}}\n        <li>{{firstName}} {{lastName}}</li>\n{{/list}}" == full_match
      assert "list" == opening_block_tag
      assert "people" == var_name
      assert "\n        <li>{{firstName}} {{lastName}}</li>\n" == inner_tpl

    end

    test "simple tags" do
      tpl = "<p>{{ first }} {{last}}</p>"
      # This regex is exactly the same as above -- we just need to do recursion on the results
      regex = ~r/{{\#(\p{L}{1,})\s{1,}(\p{L}{1,})}}(.*){{\/\1}}/us
      result = Regex.scan(regex, tpl)

      assert true == result
    end
  end

  describe "EEX" do
    test "expressions are removed" do
      tpl = "<% Elixir expression - inline with output %>"
      regex = ~r/<%.*%>/
      assert "" == String.replace(tpl, regex, "")
    end

    test "expression with equals sign are removed" do
      tpl = "<%= Elixir expression - replace with result %>"
      regex = ~r/<%.*%>/
      assert "" == String.replace(tpl, regex, "")
    end

    test "quotations are removed" do
      tpl = "<%% EEx quotation - returns the contents inside %>"
      regex = ~r/<%.*%>/
      assert "" == String.replace(tpl, regex, "")
    end

    test "comments are removed" do
      tpl = "<%# Comments - they are discarded from source %>"
      regex = ~r/<%.*%>/
      assert "" == String.replace(tpl, regex, "")
    end

    test "multiple tags are stripped" do
      tpl = "<% a %>A<%= b %>B<%% c %>C<%# d %>D"
      regex = ~r/<%.*%>/U
      result = Regex.scan(regex, tpl)
        |>  Enum.reduce(tpl, fn [x | _], acc -> String.replace(acc, x, "") end)

      assert "ABCD" == result
    end
  end
end