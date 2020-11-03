defmodule Zappa.BlockHelpers.EachTest do
  use Zappa.TestCase

  #  alias Zappa.BlockHelpers.Each

  describe "loops with regular lists" do
    test "default iterator and index" do
      actual =
        "{{#each songs}} {{@index}}: {{this}}{{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0: A Token of My Extreme 1: Stick It Out 2: Sy Borg" == strip_whitespace(actual)
    end

    test "custom iterator" do
      actual =
        "{{#each songs as |song|}} {{@index}}: {{song}}{{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0: A Token of My Extreme 1: Stick It Out 2: Sy Borg" == strip_whitespace(actual)
    end

    test "custom iterator and index" do
      actual =
        "{{#each songs as |song, trackNumber|}} {{trackNumber}}: {{song}}{{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0: A Token of My Extreme 1: Stick It Out 2: Sy Borg" == strip_whitespace(actual)
    end

    test "custom index and @index" do
      actual =
        "{{#each songs as |song, trackNumber|}} {{trackNumber}} {{@index}}: {{song}}{{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: ["A Token of My Extreme", "Stick It Out", "Sy Borg"])

      assert "0 0: A Token of My Extreme 1 1: Stick It Out 2 2: Sy Borg" ==
               strip_whitespace(actual)
    end

    test "empty list with else block" do
      actual =
        "{{#each songs}} {{this}}{{else}} Nothing to play {{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(songs: [])

      assert "Nothing to play" ==
               strip_whitespace(actual)
    end
  end

  describe "looping over maps" do
    test "map with atom keys" do
      actual =
        "{{#each moop}} {{@key}}: {{this}}{{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(moop: %{vocals: "Captain Beefheart", solo: "Meedeley meedeley meeee!"})

      assert "solo: Meedeley meedeley meeee! vocals: Captain Beefheart" ==
               strip_whitespace(actual)
    end

    test "map with string keys" do
      actual =
        "{{#each moop}} {{@key}}: {{this}}{{/each}}"
        |> Zappa.compile!()
        |> EEx.eval_string(
          moop: %{"vocals" => "Captain Beefheart", "solo" => "Meedeley meedeley meeee!"}
        )

      assert "solo: Meedeley meedeley meeee! vocals: Captain Beefheart" ==
               strip_whitespace(actual)
    end
  end
end
