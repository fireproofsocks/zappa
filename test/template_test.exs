defmodule ZappaTemplateTest do
  @moduledoc """
  This module is all about testing the complete end-to-end output.
  """

  use Zappa.TestCase

  @tag template: "the_scrutinizer"
  test "a super basic template with no monkey business", %{hbs: hbs, out: out} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(
        people: "nerds",
        output: "legislation",
        goal: "votes",
        uncontrollable: "mass behavior"
      )

    assert strip_whitespace(out) == strip_whitespace(actual)
  end

  @tag template: "heavenly_bank_account"
  test "dangerous values are escaped", %{hbs: hbs, out: out} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(
        dangerous_organization: ~S|<script>const born_again = kill("The unbelievers!); "</script>|
      )

    assert strip_whitespace(out) == strip_whitespace(actual)
  end

  @tag template: "uncle_remus"
  test "unescaped values may pass", %{hbs: hbs, out: out} do
    actual =
      Zappa.compile!(hbs)
      |> EEx.eval_string(father_figure: ~S|<bold>Charismatic Black Man</bold>|)

    assert strip_whitespace(out) == strip_whitespace(actual)
  end

  @tag template: "willie_the_pimp"
  test "partials are populated", %{hbs: hbs, out: out} do
    helpers =
      Zappa.get_default_helpers()
      |> Zappa.register_partial("denomination", "Twenny dollah bill")

    actual =
      Zappa.compile!(hbs, helpers)
      |> EEx.eval_string()

    assert strip_whitespace(out) == strip_whitespace(actual)
  end

  @tag template: "outside_now"
  test "helpers are called", %{hbs: hbs, out: out} do
    helpers =
      Zappa.get_default_helpers()
      |> Zappa.register_helper("expletive", fn _ -> "$$@!@#%" end)

    actual =
      Zappa.compile!(hbs, helpers)
      |> EEx.eval_string()

    assert strip_whitespace(out) == strip_whitespace(actual)
  end

  #  @tag template: "on_the_bus"
  #  test "a sampling of all types of tags", %{hbs: hbs, eex: eex} do
  #    helpers =
  #      Zappa.get_default_helpers()
  #      |> Zappa.register_partial("phone_number", "888-555-1212")
  #
  #    assert {:ok, actual} = Zappa.compile(hbs, helpers)
  #    assert strip_whitespace(eex) == strip_whitespace(actual)
  #  end
  #
  #  test "string to EEx" do
  #    output =
  #      "{{the_one_true_faith}} is the only religion that delivers the goods."
  #      |> Zappa.compile!()
  #      |> EEx.eval_string(the_one_true_faith: "Music")
  #
  #    assert output == "Music is the only religion that delivers the goods."
  #  end
  #
  #  test "converting binding maps to lists" do
  #    bindings =
  #      "#{__DIR__}/support/templates/willie_the_pimp.json"
  #      |> File.read!()
  #      |> Jason.decode!(keys: :atoms)
  #      |> Map.to_list()
  #
  #    hbs = ~s"""
  #      Track: {{title}}
  #      Genres:
  #      {{#each genres}}
  #        {{@index}}: {{this}}
  #      {{/each}}
  #    """
  #
  #    output =
  #      hbs
  #      |> Zappa.compile!()
  #      |> EEx.eval_string(bindings)
  #
  #    assert strip_whitespace(output) ==
  #             "Track: Willie the Pimp Genres: 0: blues rock 1: hard rock 2: jazz rock"
  #
  #    #    assert output == true
  #    # Map.to_list(%{one: 1, two: 2})
  #  end
  #
  #  test "each: maps" do
  #    bindings =
  #      "#{__DIR__}/support/templates/hot_rats.json"
  #      |> File.read!()
  #      |> Jason.decode!(keys: :atoms)
  #      |> Map.to_list()
  #
  #    hbs = ~s"""
  #      {{#each rats}}
  #        {{@key}}: {{this}}
  #      {{/each}}
  #    """
  #
  #    output =
  #      hbs
  #      |> Zappa.compile!()
  #      |> EEx.eval_string(bindings)
  #
  #    assert strip_whitespace(output) == "bunk: on piss: off"
  #
  #    #    assert output == true
  #    # Map.to_list(%{one: 1, two: 2})
  #  end
end
