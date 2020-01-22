defmodule Zappa.BlockHelpers.IfTest do
  use Zappa.TestCase

  describe "true conditions (without else" do
    test "something" do
      actual =
        "{{#if vocalist}}We got {{vocalist}}!{{/if}}"
        |> Zappa.compile!()
        |> EEx.eval_string(vocalist: "Captain Beefheart")

      assert "We got Captain Beefheart!" ==
               strip_whitespace(actual)
    end
  end

  describe "true conditions with else block" do
    @tag template: "sinister_footwear"
    test "returns the true block when the condition is true", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: true)

      assert strip_whitespace("Here you are") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the true block when the condition is a non empty string", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: "yep")

      assert strip_whitespace("Here you are") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the true block when the condition is a non zero", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: 1)

      assert strip_whitespace("Here you are") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the true block when the condition is a non-empty list", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: ["true", "dat"])

      assert strip_whitespace("Here you are") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the true block when the condition is a non-empty map", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: %{and: "how"})

      assert strip_whitespace("Here you are") == strip_whitespace(actual)
    end
  end

  describe "false conditions with else block" do
    @tag template: "sinister_footwear"
    test "returns the else block when the condition is false", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: false)

      assert strip_whitespace("Here you aren't") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the else block when the condition is zero", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: 0)

      assert strip_whitespace("Here you aren't") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the else block when the condition is empty string", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: "")


      assert strip_whitespace("Here you aren't") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the else block when the variable is an empty list", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: [])

      assert strip_whitespace("Here you aren't") == strip_whitespace(actual)
    end

    @tag template: "sinister_footwear"
    test "returns the else block when the variable is an empty map", %{hbs: hbs} do
      actual =
        Zappa.compile!(hbs)
        |> EEx.eval_string(you_are_what_you_is: %{})

      assert strip_whitespace("Here you aren't") == strip_whitespace(actual)
    end
  end
end
