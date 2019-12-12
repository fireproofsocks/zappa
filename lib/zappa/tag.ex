defmodule Zappa.Tag do
  @moduledoc """
  This struct holds information relevant to parsing a handlebars tag.
  This struct is not aware of the delimiters used to define the tag (e.g. `{{` or `{{{` etc.).

  :name - the name of the tag. E.g. `foo` from the tag `{{foo "Bar" class="zombie"}}`
  :attributes - the name of the tag. E.g. `"Bar" class="zombie"` from the tag `{{foo "Bar" class="zombie"}}`
  :contents - the full contents (name + attributes). E.g. `foo "Bar" class="zombie"` from the tag `{{foo "Bar" class="zombie"}}`
  """
  @enforce_keys [:name, :attributes, :contents]
  defstruct [:name, :attributes, :contents]
end
