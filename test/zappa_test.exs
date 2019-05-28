defmodule ZappaTest do
  use ExUnit.Case
#  doctest Zappa

#  describe "handlebars2eex/1" do
#    test "something" do
#      template = "<p>{{ first }} {{last}}</p>"
#      values = [first: "Bog", last: "Man"]
#      assert "<p><%= HtmlEntities.encode(first) %> <%= HtmlEntities.encode(last) %></p>" == Zappa.parse(template, values)
#    end
#  end

  describe "parse_triple_braces/1" do
    test "x" do
      template = "<p>{{{ first }}} {{{last}}}</p>"
      values = [first: "Bog", last: "Man"]
      assert "<p><%= first %> <%= last %></p>" == Zappa.parse_triple_braces(template)
    end
  end

#  describe "parse/3" do
#    test "something" do
#      template = "<p>{{ first }} {{last}}</p>"
#      values = [first: "Bog", last: "Man"]
#      assert "<p>Bog Man</p>" == Zappa.parse(template, values)
#    end
#  end
end
