# Changelog

## Initial Release

Includes support for:

- comment tags (both `{{! this syntax }}` and `{{!-- this other syntax which can have {{tags}} inside --}}`)
- if blocks, e.g. `{{#if true}} this will display {{/if}}`
- unless blocks
- log helper (with support for `level="error"`, `level="warn"`, `level="info"` (default), `level="debug"`)
- partials (via the `{{>example}}` syntax)
- each blocks for iterating over lists
- each blocks for iterating over objects
- arguments in helpers e.g. `{{agree_button "My Text" class="my-class" visible=true counter=4}}` or `{{#each users as |user userId|}}`
- @index
- raw-helper (Used when your final template needs to have mustache blocks.) https://handlebarsjs.com/block_helpers.html


These ones probably will not be implemented because they are too tightly coupled to the input data:
- [with](https://handlebarsjs.com/guide/builtin-helpers.html#with). Could be implemented if we temporarily override the default_regular_tag_handler
- [lookup](https://handlebarsjs.com/guide/builtin-helpers.html#lookup)
- `{{./name}}` or `{{this/name}}` or `{{this.name}}` instead of a helper of the same name
