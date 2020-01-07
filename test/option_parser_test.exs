defmodule Zappa.OptionParserTest do
  use Zappa.TestCase

  alias Zappa.OptionParser

  describe "split/1" do
    test "split mixed arguments and keywords" do
      {args, kwargs} = OptionParser.split("muffin 'man' spoon='chrome' kitchen=lab")
      assert args == [%{quoted?: false, value: "muffin"}, %{quoted?: true, value: "man"}]
      assert kwargs == %{kitchen: "lab", spoon: "chrome"}
    end
  end
end