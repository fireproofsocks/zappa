# Overview

[![Build Status](https://travis-ci.com/fireproofsocks/zappa.svg?branch=master)](https://travis-ci.com/fireproofsocks/zappa)

Zappa is an [Elixir](https://elixir-lang.org/) implementation of the [Handlebars](https://handlebarsjs.com/) templating language.  It works by [transpiling](https://en.wikipedia.org/wiki/Source-to-source_compiler) handlebars templates into native EEx templates (i.e. [Embedded Elixir](https://hexdocs.pm/eex/EEx.html)).  The mother of its invention was the need to have untrusted users create and edit templates to format their own data.  EEx templates would have been unacceptable for the purpose because they do not restrict what code is allowed to run, and the [Mustache Template System](https://en.wikipedia.org/wiki/Mustache_%28template_system%29) lacked the features (if-statements, loops, custom functions, etc.) that were needed.
 
Like the name "handlebars", "Zappa" nods to the hirsute nomenclature of its predecessors and pays tribute to the late great iconoclastic, [Frank Zappa](https://en.wikipedia.org/wiki/Frank_Zappa).

## Features

Implementing functional templates using the Handlebars syntax is a bit like trying to grow a [Watermelon in Easter Hay](https://www.youtube.com/watch?v=_3cu8sDa90Y): its syntax rules are poorly defined, inconsistent, but nonetheless popular.  So instead of re-inventing yet another template syntax, we pony up to the familiar tropes and offer the following features:

- `{{! short comments }}` and `{{!-- long comments with {{tags}} --}}`
- `{{#if}} statements {{/if}}` and other block helpers
- `{{log helper}}` and other functional helpers
- `{{>partials}}` to include re-used content 
- ability to register your own helpers

See the [CHANGELOG](https://github.com/fireproofsocks/zappa/blob/master/CHANGELOG.md) for a detailed list of the currently supported features.

## Who Should Use this Package?

Zappa can help you in any of the following conditions:

- You have to let untrusted users create and edit formatting templates and you can't have them running arbitrary code.
- You have outgrown a simple template language like Mustache.
- You prefer the Handlebars syntax and don't want or need EEx for whatever reason.
- You are messed up from music, disease, or heartbreak.

If [Embedded Elixir (EEx)](https://hexdocs.pm/eex/EEx.html) templates are working for you, then you have what you need already.
If you don't need the extra logic and features that Handlebars templates provide, then you can have a look at these Elixir Mustache implementations: 

- [mustache](https://hex.pm/packages/mustache)
- [bbmustache](https://hex.pm/packages/bbmustache)
- [fumanchu](https://hex.pm/packages/fumanchu)
- [stache](https://hex.pm/packages/stache)



Ready to get started? [Getting Started](getting_started.html)
