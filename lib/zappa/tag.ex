defmodule Zappa.Tag do
  @moduledoc """
  This struct holds information relevant to parsing a handlebars tag.
  This struct is not aware of the delimiters used to define the tag (e.g. `{{` or `{{{` etc.).

  :name - the name of the tag. E.g. `foo` from the tag `{{foo "Bar" class="zombie"}}`
  :options - the options of the tag. E.g. `"Bar" class="zombie"` from the tag `{{foo "Bar" class="zombie"}}`
  :contents - the full raw contents (name + options). E.g. `foo "Bar" class="zombie"` from the tag `{{foo "Bar" class="zombie"}}`
  :block_contents - the full (parsed) contents of a block (only applicable for block tags)
  """
  @enforce_keys [:name, :options, :contents]
  defstruct [:name, :options, :contents, :block_contents]
end
