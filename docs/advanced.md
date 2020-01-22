# Advanced Customization

Zappa attempts to be flexible to support customizations. Here are a couple scenarios that demonstrate how you can do advanced customizations on your template compilation.

## I need to create JSON templates

By default, Zappa uses HTML encoding to escape values for regular tags, e.g. `{{name}}`. If the final output of your data is meant to be JSON, then you should use a JSON encoder instead. You can do this by registering a helper function in the `"__escaped__"` space that points to your own helper function, e.g.

```elixir
helpers = Zappa.get_default_helpers()
helpers = Zappa.register_helper("__escaped__", &MyApp.JsonEscapedDefault.parse/1)
```

Assuming that `MyApp.JsonEscapedDefault` looked something like the below:  

```elixir
defmodule MyApp.JsonEscapedDefault do
  
  alias Zappa.Tag

  @spec parse(%Tag{}) :: {:ok, String.t()} | {:ok, String.t()}
  def parse(%Tag{raw_options: ""} = tag) do
    {:ok, "<%= Jason.encode!(#{tag.name}) %>"}
  end

  @spec parse(%Tag{}) :: {:ok, String.t()} | {:error, String.t()}
  def parse(_tag) do
    {:error, "Options not allowed for regular tags unless a helper is registered"}
  end
end
```

This would cause any `{{tag}}` to format its value as properly encoded JSON.  If you only wish binary string values to be accepted, you could enforce  this rule via guard clauses. Look to the `Zappa.Helpers.EscapedDefault` and the `Zappa.HtmlEncoder` module for inspiration.


## Disallowing unescaped values

If you always want your values to be safely escaped, you could override the `"__unescaped__"` helper and point it to the same function that handles the escaped values, e.g. 

```elixir
helpers = Zappa.get_default_helpers()
helpers = Zappa.register_helper("__unescaped__", &Zappa.Helpers.EscapedDefault.parse/1)
```

That would have the effect of `{{tag}}` and `{{{tag}}}` producing the same result.


### Register ALL helpers

There's not requirement that you use the default `%Zappa.Helpers{}` struct that is returned from `Zappa.get_default_helpers/0`.  If needed, you can provide your own helpers and pass that into the `compile` functions.  This could be useful in cases where you need stricter control over the functionality allowed in your Handlebars templates.