defmodule Zappa.Helpers do
  @moduledoc """
  This struct is a map containing the following keys:

  :helpers - callbacks used simple {{tags}}. The
  :block_helpers - These functions receive a %Zappa.Tag{} struct and a string representing the contents of the block.
  :partials - callbacks used to resolve "partials" tags, e.g. {{>example}}. These functions receive no arguments.
  """

  defstruct helpers: %{},
            block_helpers: %{},
            partials: %{}
end
