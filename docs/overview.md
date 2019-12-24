# Overview

Zappa is an [Elixir](https://elixir-lang.org/) implementation of the [Handlebars](https://handlebarsjs.com/) templating language.  The mother of its invention was the need to have untrusted users create and edit templates to format their own data.  [EEx]((https://hexdocs.pm/eex/EEx.html) templates would have been unacceptable for the purpose because they do not restrict what code is allowed to run, and the [Mustache Template System](https://en.wikipedia.org/wiki/Mustache_%28template_system%29) lacked the features that were needed (if-statements, loops, custom functions, etc.).
 
Like "handlebars", Zappa is a name that nods to the hirsute nomenclature of its predecessors and pays tribute to [Frank Zappa](https://en.wikipedia.org/wiki/Frank_Zappa), the iconoclastic grower of [watermelons in Easter hay](https://www.youtube.com/watch?v=xFvzfNtXnVU).

Zappa [transpiles](https://en.wikipedia.org/wiki/Source-to-source_compiler) handlebars templates into native EEx templates (i.e. [Embedded Elixir](https://hexdocs.pm/eex/EEx.html)).  

This implementation relies on tail recursion (and not regular expressions).

Implementing functional templates using the Handlebars syntax is like trying to grow a [Watermelon in Easter Hay](https://www.youtube.com/watch?v=_3cu8sDa90Y): its syntax rules are poorly defined, inconsistent, but nonetheless popular.  So instead of re-inventing yet another template syntax, we pony up to the familiar tropes.