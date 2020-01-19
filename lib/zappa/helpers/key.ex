defmodule Zappa.Helpers.Key do
  @moduledoc false
  # Handles instances of {{@key}}
  # The variable name chosen here should match up with the one created in the each.ex parser.
  alias Zappa.Tag

  def parse(%Tag{raw_options: ""}) do
    {:ok, "<%= key___helper %>"}
  end

  def parse(_tag) do
    {:error, "The {{@key}} tag does not allow options."}
  end
end
