# Block Helpers

In Handlebars syntax, block helpers are denoted with an opening and closing tag, e.g. `{{#block}} ... {{/block}}`.

Like the regular [helpers](helpers.html), block-helpers are implemented as callback functions. They are registered into the `%Zappa.Helpers{}` struct via the `Zappa.register_block/3` function.  The callback function should accept a single argument: a `%Zappa.Tag{}` struct.

## `each`

This module implements the [each](https://handlebarsjs.com/guide/builtin-helpers.html#each) block-helper as
demonstrated by Handlebars. It is one of the built-in block helpers.

The `each` helper allows your template to iterate over a list or map. Although this "one-size-fits-all" approach makes
more sense in Handlebars' native Javascript, but it is possible to obfuscate the internals in Elixir too.

By default, the current item is available using the `{{this}}` tag, and like Handlebars, Zappa exposes a `{{@index}}`
helper which will indicate the integer position in the list (zero-based). This is accomplished via a dedicated
`@index` helper.  For feature parity with Handlebars, `{{else}}` blocks are also supported (via another dedicated
helper).


### Handlebars Examples

```
{{#each discography}}
    {{this}} was a hit!
{{/each}}
```

### Using an `{{else}}` block:

```
{{#each catholic_girls}}
    {{this}} in a little white dress!
{{else}}
    There are no Catholic Girls.
{{/each}}
```

