defmodule Zappa.TestCase do
  @moduledoc """
  This module includes some shared utility functions and the convenience functions for setting up implicit
  [unit test fixtures](https://en.wikipedia.org/wiki/Test_fixture).
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Zappa.Helpers

      @doc """
      This function eliminates extra whitespace making it easier to test the compiler output without whitespace errors.
      """
      def strip_whitespace(str) do
        String.replace(str, ~r/\n/, " ")
        |> String.replace(~r/\s+/, " ")
        |> String.trim()
      end
    end
  end

  # Setup a pipeline for manipulating the context metadata.
  setup [:append_templates]

  # Trigger this by adding a tag to your test, e.g. @tag template: "some_stub"
  # This works by loading up 2 files:
  #   - the handlebars template (.hbs)
  #   - the EEx template (.eex)
  defp append_templates(%{template: filename}) do
    handlebars =
      "#{__DIR__}/templates/#{filename}.hbs"
      |> File.read!()

    eex =
      "#{__DIR__}/templates/#{filename}.eex"
      |> File.read!()

    %{
      hbs: handlebars,
      eex: eex
    }
  end

  defp append_templates(context), do: context
end
