defmodule Zappa.BlockHelpers.UnlessTest do
  use Zappa.TestCase

  @tag template: "uncle_remus2"
  test "unless with else block returns the false block when the condition is false", %{hbs: hbs} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(we_get_sprayed_with_a_hose: false)

    assert strip_whitespace("It ain't bad in the day") == strip_whitespace(actual)
  end

  @tag template: "uncle_remus2"
  test "unless with else block returns the else block when the condition is true", %{hbs: hbs} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(we_get_sprayed_with_a_hose: true)

    assert strip_whitespace("There be bigots") == strip_whitespace(actual)
  end
end
