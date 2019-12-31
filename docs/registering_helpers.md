# Registering Helpers

In order to be useful, Zappa relies on callback functions inside the `%Zappa.Helpers{}` struct. 

All helper functions receive a `%Zappa.Tag{}` struct as their single argument.

## Helpers

```elixir

```

## Blocks Helpers

```elixir

```


## Partials


### Registering a String

For convenience, you can register a partial as a simple string.  The string may contain handlebar tags.

```elixir
helpers = Zappa.get_default_helpers()
|> Zappa.register_partial("contact_email", "central.scrutinizer@joes.garage")
```

### Registering a Function

These are functionally equivalent to regular helper functions, but they use a separate namespace and are triggered by different delimiters in the parser.


```elixir
helpers = Zappa.get_default_helpers()
|> Zappa.register_partial("current_date", fn(_tag) -> DateTime.utc_now() end)
```

```handlebars
{{>current_date}}
```

"2019-12-22 02:19:00.787152Z"