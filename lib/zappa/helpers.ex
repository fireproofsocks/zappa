defmodule Zappa.Helpers do
  @moduledoc """
  This struct contains maps that define various types of callback functions. The functions housed in this struct are
  what give Zappa its power. An instance of this struct can be passed to `Zappa.compile/2`.

  Some functions are registered by default: see `Zappa.get_default_helpers/0`; the default helpers are used when
  `Zappa.compile/1` is called.

  The keys in this struct are the following:

  - `:helpers` - contains a map of callbacks used by simple tags, e.g. `{{verse1}}`. See `Zappa.register_helper/3`.
  - `:block_helpers` - contains a map of callbacks used by block tags, e.g. `{{#refrain}}Catholic girls{{/refrain}}`. See `Zappa.register_block/3`.
  - `:partials` - callbacks used to resolve "partials" tags, e.g. `{{>girl_on_the_bus}}`. See `Zappa.register_partial/3`.
  """

  defstruct helpers: %{},
            block_helpers: %{},
            partials: %{}
end
