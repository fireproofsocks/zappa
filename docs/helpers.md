# Built-In Helpers

Zappa ships with a few built-in helpers provided.

## Block Helpers

Block helpers are denoted with an opening and closing tag.

### each

The `each` helper allows your template to iterate over a list.  By default, the current item is available using the `{{this}}` tag.

```
{{#each discography}}
    {{this}} was a hit!
{{/each}}
```

### if

The contents of the block display when the statement evaluates to **true**.

```
{{#if it_hurts_when_i_pee}}
    I got it from the toilet seat
{{else}}
    I had no liaison with the taco stand lady
{{/if}}
```

### unless

This is the inverse of the `if` block. Its contents display when the statement evaluates to **false**.
```
{{#unless you_speak_german}}
    You cannot join the Church of Appliantology!
{{/unless}}
```

You can use the `else` clauses within this block.

----------------------------

## Regular Helpers

Regular helpers are denoted using the standard double-braces, e.g. `{{helper}}`.

### `else`

`{{else}}` tags should only be used in conjunction with block-tags that support them, e.g. `if` or `unless`.

It's a bit of a quirk that this is implemented as a standard helper, but this makes things easier for the block-helpers so they don't have to worry about parsing the contents of the block.

### `log`

This helper allows your template to send messages to the logger **when the template is rendered**. 

### `__escaped_default__`

This is a special helper that is used when rendering a regular tag, e.g. `{{dont_eat_the_yellow_snow}}`.  See the section on [advanced customization](advanced.md).

### `__unescaped_default__`

This is a special helper that is used when rendering an unescaped tag, e.g. `{{{my_guitar_wants_to_kill_your_mama}}}`.  See the section on [advanced customization](advanced.md).