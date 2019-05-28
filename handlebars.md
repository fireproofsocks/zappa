# Handlebars

Notes on Handlebars syntax:

## HTML Escaping

- `{{ }}` - escape HTML characters.
- `{{{ }}}` - Raw. do NOT escape HTML characters.


```
<div class="entry">
  <h1>{{title}}</h1>
  <div class="body">
    {{{body}}}
  </div>
</div>
```

```elixir
%{
  title: "All about <p> Tags",
  body: "<p>This is a post about &lt;p&gt; tags</p>"
}
```

```
<div class="entry">
  <h1>All About &lt;p&gt; Tags</h1>
  <div class="body">
    <p>This is a post about &lt;p&gt; tags</p>
  </div>
</div>
```

## Block Expressions

Block expressions have a start tag denoted with a `#`, e.g. `#list`, and an ending tag denoted with a `/`, e.g. `/list`:

```
{{#list people}}{{firstName}} {{lastName}}{{/list}}
```

```elixir
%{
  people: [
    %{firstName: "Yehuda", lastName: "Katz"},
    %{firstName: "Carl", lastName: "Lerche"},
    %{firstName: "Alan", lastName: "Johnson"}
  ]
}
```


## Dot Notation for Nested Data

```
<div class="entry">
  <h1>{{title}}</h1>
  <h2>By {{author.name}}</h2>

  <div class="body">
    {{body}}
  </div>
</div>
```


## Paths

```
{{permalink}}
{{#each comments}}
  {{../permalink}}

  {{#if title}}
    {{../permalink}}
  {{/if}}
{{/each}}
```

## Template Comments

```
{{!-- --}} or {{! }}
```

## Helpers

Look closely at the `fullName` helper:

```javascript
Handlebars.registerHelper('fullName', function(person) {
  return person.firstName + " " + person.lastName;
});
```

And how it can get passed the `author` variable:
```
<div class="post">
  <h1>By {{fullName author}}</h1>
  <div class="body">{{body}}</div>

  <h1>Comments</h1>

  {{#each comments}}
  <h2>By {{fullName author}}</h2>
  <div class="body">{{body}}</div>
  {{/each}}
</div>
```

You can also pass arguments to your helpers using HTML-ish key/value syntax:

```
{{agree_button "My Text" class="my-class" visible=true counter=4}}
```

### Literals

Pretty much, these are just helpers, but we make the point that they can also be static values.

## Partials

Similar (functionally equivalent?) to helpers, you can register "partials" and call them using the `>` sigil:

```javascript
Handlebars.registerPartial('userMessage',
    '<{{tagName}}>By {{author.firstName}} {{author.lastName}}</{{tagName}}>'
    + '<div class="body">{{body}}</div>');
```

```
<div class="post">
  {{> userMessage tagName="h1" }}

  <h1>Comments</h1>

  {{#each comments}}
    {{> userMessage tagName="h2" }}
  {{/each}}
</div>
```

## Built-in Helpers

https://handlebarsjs.com/builtin_helpers.html

### `if`

### `unless`

### `with`

demonstrates how to pass a parameter to your helper

```
<div class="entry">
  <h1>{{title}}</h1>
  {{#with story}}
    <div class="intro">{{{intro}}}</div>
    <div class="body">{{{body}}}</div>
  {{/with}}
</div>
```

### `noop`
https://handlebarsjs.com/block_helpers.html
\


### `each`

Remember that you can reference the index of the current loop using `@index`:
```
{{#each array}}
  {{@index}}: {{this}}
{{/each}}
```

OR, you can use [block parameters](https://handlebarsjs.com/block_helpers.html#block-params):

```
{{#each users as |user userId|}}
  Id: {{userId}} Name: {{user.name}}
{{/each}}
```

You can use the `{{else}}` block to show something when the list is empty:

```
{{#each paragraphs}}
  <p>{{this}}</p>
{{else}}
  <p class="empty">No content</p>
{{/each}}
```

Sort of a pain, but you can do a comma-separated list by adding in an `{{#if}}` block.
In this case, it evaluates to false for the first iteration (where `@index` equals zero), 
and then it adds a comma before every other item. 

```
{{#each this}}
    {{#if @index}}, {{/if}}
    <span>{{alert_description}}</span>
{{/each}}
```


### `raw-helper` Raw Blocks

Used when your final template needs to have mustache blocks.

```
{{{{raw-helper}}}}
  {{bar}}
{{{{/raw-helper}}}}
```

