# Advanced Customization

Zappa attempts to be flexible to support customizations.

## Registering Your own Default Helpers


### `__escaped_default__`

This is a special helper that is the default handler for all regular HTML-escaped tags, e.g. `{{studio}}`.  Its job is to ensure that any HTML entities in the input variables are properly escaped when the template is rendered.  The built-in implementation relies on the [html_entities](https://hex.pm/packages/html_entities) package (which is why the installation instructions tell you to list it in your `mix.exs`).

### `__unescaped_default__`

This is a special helper.

### Register ALL helpers

There's not requirement that you use the default `%Zappa.Helpers{}` struct that is returned from `Zappa.get_default_helpers/0`.  If needed, you can provide your own helpers and pass that into the `compile` functions.  This could be useful in cases where you need stricter control over the functionality allowed in your Handlebars templates.