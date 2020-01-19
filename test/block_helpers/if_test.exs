defmodule Zappa.BlockHelpers.IfTest do
  use Zappa.TestCase

  @tag template: "sinister_footwear"
  test "if with else block returns the true block when the condition is true", %{hbs: hbs} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(you_are_what_you_is: true)

    assert strip_whitespace("Here you are") == strip_whitespace(actual)
  end

  @tag template: "sinister_footwear"
  test "if with else block returns the else block when the condition is false", %{hbs: hbs} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(you_are_what_you_is: false)

    assert strip_whitespace("Here you aren't") == strip_whitespace(actual)
  end
end
