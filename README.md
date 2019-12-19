# Zappa

Handlebars templates in Elixir (still in dev, but now minimally functional!)

Zappa is an Elixir implementation of the [Handlebars](https://handlebarsjs.com/) templating language that works by converting handlebars templates into native EEx templates (i.e. [Embedded Elixir](https://hexdocs.pm/eex/EEx.html)).  Handlebars builds on the [Mustache Template System](https://en.wikipedia.org/wiki/Mustache_%28template_system%29) by adding in some logic and functions to the templates.  Like "handlebars", Zappa is a name that nods to the hirsute nomenclature of its predecessors and pays tribute to [Frank Zappa](https://en.wikipedia.org/wiki/Frank_Zappa), the iconic grower of [watermelons in Easter hay](https://www.youtube.com/watch?v=xFvzfNtXnVU).

The specific use case that drove development of Zappa was to provide _untrusted users_ the ability to create and edit simplified templates. EEx templates would have been unacceptable for the purpose because they do not restrict what code is allowed to run, and Mustache lacked the features that were required in these templates.

See [Handlebars Documentation](https://devdocs.io/handlebars/)

## Similar Packages

If you don't need the logic that Handlebars templates have, then you can have a look at these Elixir Mustache implementations:

- [mustache](https://hex.pm/packages/mustache)
- [bbmustache](https://hex.pm/packages/bbmustache)
- [fumanchu](https://hex.pm/packages/fumanchu)
- [stache](https://hex.pm/packages/stache)

Or stick to the in-house [Embedded Elixir (EEx)](https://hexdocs.pm/eex/EEx.html) templates.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `zappa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zappa, "~> 0.1.0"}
  ]
end
```

For development purposes, you can install this repository using `git` and installing its dependencies:

```
git clone git@github.com:fireproofsocks/zappa.git
mix deps.get
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/zappa](https://hexdocs.pm/zappa).

## Features

- comments
- if blocks
- unless blocks
- log helper
- partials
- each (arrays)

## TODO:

- each (objects)
- @index
- raw-helper (Used when your final template needs to have mustache blocks.) https://handlebarsjs.com/block_helpers.html
`{{./name}}` or `{{this/name}}` or `{{this.name}}` instead of a helper of the same name
- arguments in helpers e.g. `{{agree_button "My Text" class="my-class" visible=true counter=4}}` or `{{#each users as |user userId|}}`

## Not Implemented

These ones probably will not be implemented because they are too tightly coupled to the input data:
- [with](https://handlebarsjs.com/guide/builtin-helpers.html#with). Could be implemented if we temporarily override the default_regular_tag_handler
- [lookup](https://handlebarsjs.com/guide/builtin-helpers.html#lookup)