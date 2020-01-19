# Zappa

[![Hex pm](http://img.shields.io/hexpm/v/zappa.svg?style=flat)](https://hex.pm/packages/zappa)[![Build Status](https://travis-ci.com/fireproofsocks/zappa.svg?branch=master)](https://travis-ci.com/fireproofsocks/zappa)

Zappa is an [Elixir](https://elixir-lang.org/) implementation of the [Handlebars](https://handlebarsjs.com/) templating language.  It works by converting handlebars templates into native EEx templates (i.e. [Embedded Elixir](https://hexdocs.pm/eex/EEx.html)).  The mother of its invention was the need to have untrusted users create and edit templates to format their own data.  [EEx](https://hexdocs.pm/eex/EEx.html) templates would have been unacceptable for the purpose because they do not restrict what code is allowed to run, and the [Mustache Template System](https://en.wikipedia.org/wiki/Mustache_%28template_system%29) lacked the features that were needed (if-statements, loops, custom functions, etc.).
 
Like the name "Handlebars", "Zappa" nods to the hirsute nomenclature of its predecessors (i.e. Handlebars, Mustache) and pays tribute to the late great iconoclastic [Frank Zappa](https://en.wikipedia.org/wiki/Frank_Zappa).


## Similar Packages

If you don't need the logic that Handlebars templates have, then you can have a look at these Elixir Mustache implementations:

- [mustache](https://hex.pm/packages/mustache)
- [bbmustache](https://hex.pm/packages/bbmustache)
- [fumanchu](https://hex.pm/packages/fumanchu)
- [stache](https://hex.pm/packages/stache)

Or if you don't need to carefully deal executing templates created by untrusted users, then stick to the regular [Embedded Elixir (EEx)](https://hexdocs.pm/eex/EEx.html) templates.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `zappa` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:zappa, "~> 1.0.0"}
  ]
end
```

For development purposes, you can install this repository using `git`:

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

Create default function for comments
Clean up tests
cleanup setup_all... there's not always an .out file
Move @index_var into config
Dot notation for accessing variables
Add docs for built-in helpers, add examples
Update CHANGELOG
Clean up docs!
Javascript Encoder?

--

## Not Implemented


- `{{./name}}` or `{{this/name}}` or `{{this.name}}` instead of a helper of the same name
- Hooks

These ones probably will not be implemented because they are too tightly coupled to the input data:
- [with](https://handlebarsjs.com/guide/builtin-helpers.html#with). Could be implemented if we temporarily override the default `__escaped__` helper
- [lookup](https://handlebarsjs.com/guide/builtin-helpers.html#lookup)
- Subexpressions https://handlebarsjs.com/guide/expressions.html#subexpressions
- Whitespace control: https://handlebarsjs.com/guide/expressions.html#whitespace-control
- Escaping expressions: https://handlebarsjs.com/guide/expressions.html#escaping-handlebars-expressions