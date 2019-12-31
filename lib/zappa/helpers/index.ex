defmodule Zappa.Helpers.Index do
  @moduledoc false
  # Handles instances of {{@index}}
  # The variable name chosen here should match up with the one created in the each.ex parser.
  alias Zappa.Tag

  def parse_index(%Tag{options: ""}) do
    {:ok, "<%= index___helper %>"}
  end

  def parse_index(_tag) do
    {:error, "The {{@index}} tag does not allow options."}
  end
end
