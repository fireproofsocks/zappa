defmodule Zappa.BlockHelpers.ForEachTest do
  use Zappa.TestCase

  #  alias Zappa.BlockHelpers.Each

  describe "foreach loops with regular lists" do
    test "default iterator and index" do
      actual =
        "{{#foreach songs}} {{@index}}: {{this}}{{/foreach}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0: A Token of My Extreme 1: Stick It Out 2: Sy Borg" == strip_whitespace(actual)
    end

    test "custom iterator" do
      actual =
        "{{#foreach songs as |song|}} {{@index}}: {{song}}{{/foreach}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0: A Token of My Extreme 1: Stick It Out 2: Sy Borg" == strip_whitespace(actual)
    end

    test "custom iterator and index" do
      actual =
        "{{#foreach songs as |song, trackNumber|}} {{trackNumber}}: {{song}}{{/foreach}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0: A Token of My Extreme 1: Stick It Out 2: Sy Borg" == strip_whitespace(actual)
    end

    test "custom index and @index" do
      actual =
        "{{#foreach songs as |song, trackNumber|}} {{trackNumber}} {{@index}}: {{song}}{{/foreach}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0 0: A Token of My Extreme 1 1: Stick It Out 2 2: Sy Borg" ==
               strip_whitespace(actual)
    end
  end
end
