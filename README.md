# Zappa

Zappa is an [Elixir](https://elixir-lang.org/) implementation of the [Handlebars](https://handlebarsjs.com/) templating language.  It works by [transpiling](https://en.wikipedia.org/wiki/Source-to-source_compiler) handlebars templates into native EEx templates (i.e. [Embedded Elixir](https://hexdocs.pm/eex/EEx.html)).  The mother of its invention was the need to have untrusted users create and edit templates to format their own data.  [EEx](https://hexdocs.pm/eex/EEx.html) templates would have been unacceptable for the purpose because they do not restrict what code is allowed to run, and the [Mustache Template System](https://en.wikipedia.org/wiki/Mustache_%28template_system%29) lacked the features that were needed (if-statements, loops, custom functions, etc.).
 
Like the name "handlebars", "Zappa" nods to the hirsute nomenclature of its predecessors and pays tribute to the late great iconoclastic, [Frank Zappa](https://en.wikipedia.org/wiki/Frank_Zappa).


## Similar Packages

If you don't need the logic that Handlebars templates have, then you can have a look at these Elixir Mustache implementations:

- [mustache](https://hex.pm/packages/mustache)
- [bbmustache](https://hex.pm/packages/bbmustache)
- [fumanchu](https://hex.pm/packages/fumanchu)
- [stache](https://hex.pm/packages/stache)

Or if you don't need to carefully deal executing templates created by untrusted users, then stick to the regular [Embedded Elixir (EEx)](https://hexdocs.pm/eex/EEx.html) templates.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `zappa` to your list of dependencies in `mix.exs`.  For the default installation, you should also install the `html_entities` package: it is what Zappa will use to render default tags in your templates.

```elixir
def deps do
  [
    {:html_entities, "~> 0.5.0"},
    {:zappa, "~> 1.0.0"}
  ]
end
```

For development purposes, you can install this repository using `git` and installing its dependencies:

```
git clone git@github.com:fireproofsocks/zappa.git
cd zappa
mix deps.get
```

See [CONTRIBUTING](CONTRIBUTING.md) for notes on contributing features and bug fixes.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/zappa](https://hexdocs.pm/zappa).


## TODO:

- each with else blocks
- each (objects)
- @index
- raw-helper (Used when your final template needs to have mustache blocks.) https://handlebarsjs.com/block_helpers.html
`{{./name}}` or `{{this/name}}` or `{{this.name}}` instead of a helper of the same name
- arguments in helpers e.g. `{{agree_button "My Text" class="my-class" visible=true counter=4}}` or `{{#each users as |user userId|}}`

## Not Implemented

These ones probably will not be implemented because they are too tightly coupled to the input data:
- [with](https://handlebarsjs.com/guide/builtin-helpers.html#with). Could be implemented if we temporarily override the default `__escaped__` helper
- [lookup](https://handlebarsjs.com/guide/builtin-helpers.html#lookup)
