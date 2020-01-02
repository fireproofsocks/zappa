# Block Helpers

In Handlebars syntax, block helpers are denoted with an opening and closing tag, e.g. `{{#block}} ... {{/block}}`.

Like the regular [helpers](helpers.html), block-helpers are implemented as callback functions. They are registered into the `%Zappa.Helpers{}` struct via the `Zappa.register_block/3` function.  The callback function should accept a single argument: a `%Zappa.Tag{}` struct.


