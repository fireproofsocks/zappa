defmodule Zappa.Helpers.Index do
  @moduledoc false
  # Handles instances of {{@index}}
  # The variable name chosen here should match up with the one created in the each.ex parser.
  alias Zappa.Tag

  def parse(%Tag{raw_options: ""}) do
    {:ok, "<%= index___helper %>"}
  end

  def parse(_tag) do
    {:error, "The {{@index}} tag does not allow options."}
  end
end
