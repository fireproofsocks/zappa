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
    helpers =
      Zappa.get_default_helpers()
      |> Zappa.register_partial("phone_number", "888-555-1212")

    assert {:ok, actual} = Zappa.compile(hbs, helpers)
    assert strip_whitespace(eex) == strip_whitespace(actual)
  end

  test "string to EEx" do
    output =
      "{{the_one_true_faith}} is the only religion that delivers the goods."
      |> Zappa.compile!()
      |> EEx.eval_string(the_one_true_faith: "Music")

    assert output == "Music is the only religion that delivers the goods."
  end

  test "converting maps to lists" do
    bindings =
      "#{__DIR__}/support/templates/willie_the_pimp.json"
      |> File.read!()
      |> Jason.decode!(keys: :atoms)
      |> Map.to_list()

    hbs = ~s"""
      Track: {{title}}
      Genres:
      {{#each genres}}
        {{@index}}: {{this}}
      {{/each}}
    """

    output =
      hbs
      |> Zappa.compile!()
      |> EEx.eval_string(bindings)

    assert strip_whitespace(output) ==
             "Track: Willie the Pimp Genres: 0: blues rock 1: hard rock 2: jazz rock"

    #    assert output == true
    # Map.to_list(%{one: 1, two: 2})
  end
end
