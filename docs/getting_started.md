# Getting Started

## Who Should Use this Package?

Zappa can help you in the following conditions:

1. You have to let untrusted users create and edit formatting templates and you can't have them running arbitrary code.
2. Your templates require more features than what is available in a simple template language like Mustache.

If you don't need to deal executing templates created by untrusted users, then stick to [Embedded Elixir (EEx)](https://hexdocs.pm/eex/EEx.html) templates.
If you don't need the extra logic and features that Handlebars templates provide, then you can have a look at these Elixir Mustache implementations: 

- [mustache](https://hex.pm/packages/mustache)
- [bbmustache](https://hex.pm/packages/bbmustache)
- [fumanchu](https://hex.pm/packages/fumanchu)
- [stache](https://hex.pm/packages/stache)

## Your First Template

```elixir
handlebars = ~s"""
Music is the only religion that delivers the goods.

Modern Americans behave as if intelligence were some sort of hideous deformity.

Republicans stand for raw, unbridled evil and greed and ignorance smothered in balloons and ribbons.

Americans like to talk about (or be told about) Democracy but, when put to the test, usually find it to be an 'inconvenience.' We have opted instead for an authoritarian system disguised as a Democracy. We pay through the nose for an enormous joke-of-a-government, let it push us around, and then wonder how all those assholes got in there.
"""
```

## Registering Helper Functions