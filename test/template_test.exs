defmodule ZappaTemplateTest do
  @moduledoc """
  This file is focused solely on testing template compilation.
  """

  use Zappa.TestCase

  @tag template: "the_scrutinizer"
  test "a super basic template with no monkey business", %{hbs: hbs, eex: eex} do
      assert {:ok, actual} = Zappa.compile(hbs)
      assert strip_whitespace(eex) == strip_whitespace(actual)
  end

  @tag template: "on_the_bus"
  test "a sampling of all types of tags", %{hbs: hbs, eex: eex} do
    helpers = Zappa.get_default_helpers()
    |> Zappa.register_partial("phone_number", "888-555-1212")
    assert {:ok, actual} = Zappa.compile(hbs, helpers)
    assert strip_whitespace(eex) == strip_whitespace(actual)
  end
end
