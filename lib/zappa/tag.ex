defmodule Zappa.Tag do
  @moduledoc """
  This struct holds information relevant to parsing a handlebars tag. All helper functions registered in the
  `%Zappa.Helpers{}` struct are passed a `%Zappa.Tag{}` struct as their single argument.

  This struct is not aware of the delimiters used to define the tag (e.g. `{{` or `{{{` etc.).

  ## %Zappa.Tag{} Keys

  - `:name` - the identifying name of the tag.
  - `:raw_options` - everything but the name.
  - `:raw_contents` - the full raw contents (name + raw_options). E.g. `song "Joe's Garage" volume="high"` from the tag `{{song "Joe's Garage" volume="high"}}`
  - `:args` - a list of parsed arguments. Each argument in the list is represented as a map with keys for `:value` and
    `:quoted?` so the implementations can react differently if a value was passed directly as a variable (unquoted)
    or as a literal quoted string.
  - `:kwargs` - a map of [hash arguments](https://handlebarsjs.com/guide/block-helpers.html#hash-arguments).
  - `:parsed_block_contents` - the full parsed contents of a block (only applicable for block tags)
  - `:unparsed_block_contents` - the full unparsed contents of a block (only applicable for raw blocks)
  - `:opening_delimiter` - the string that marked the beginning of the tag.
  - `:closing_delimiter` - the string that marked the end of the tag.

  The terminology here borrows from Python were [kwargs](https://pythontips.com/2013/08/04/args-and-kwargs-in-python-explained/)
  refers to "keyword arguments".

  ## Examples

  Tag: ``{{song "Joe's Garage" volume="high"}}`

  - `:name`: `song`
  - `:raw_contents`: `song "Joe's Garage" volume="high"`
  - `:raw_options`: `"Joe's Garage" volume="high"`
  - `:parsed_block_contents`: nil

  """

  defstruct name: "",
            raw_options: "",
            raw_contents: "",
            args: [],
            kwargs: %{},
            parsed_block_contents: nil,
            unparsed_block_contents: nil,
            opening_delimiter: "",
            closing_delimiter: ""

  @type t :: %__MODULE__{
               name: String.t,
               raw_options: String.t,
               raw_contents: String.t,
               args: list,
               kwargs: map,
               parsed_block_contents: String.t | nil,
               unparsed_block_contents: String.t | nil,
               opening_delimiter: String.t,
               closing_delimiter: String.t
             }
end
