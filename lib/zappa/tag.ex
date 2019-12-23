defmodule Zappa.Tag do
  @moduledoc """
  This struct holds information relevant to parsing a handlebars tag. All helper functions registered in the
  `%Zappa.Helpers{}` struct are passed a `%Zappa.Tag{}` struct as their single argument.

  Note: this struct is not aware of the delimiters used to define the tag (e.g. `{{` or `{{{` etc.).

  ### %Zappa.Tag{} Keys

  - `:name` - the name of the tag. E.g. `foo` from the tag `{{song "Joe's Garage" volume="high"}}`
  - `:options` - the options of the tag. E.g. `"Joe's Garage" volume="high"` from the tag `{{song "Joe's Garage" volume="high"}}`
  - `:raw_contents` - the full raw contents (name + options). E.g. `song "Joe's Garage" volume="high"` from the tag `{{song "Joe's Garage" volume="high"}}`
  - `:block_contents` - the full parsed contents of a block (only applicable for block tags)

  """
  @enforce_keys [:name, :options, :raw_contents]
  defstruct [:name, :options, :raw_contents, :block_contents]
end
