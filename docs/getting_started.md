# Getting Started

## Installation

For regular installation, add `:zappa` to your `mix.exs` dependencies, AND include the [:html_entities](https://hex.pm/packages/html_entities) package as well:

```elixir
defp deps do
    [
      {:zappa, "~> 1.0.0"},
      {:html_entities, "~> 0.5.0"},
    ]
end
```

**DO NOT FORGET to install :html_entities**!  The EEx code that Zappa generates will reference the `HtmlEntities.encode/1` function, so you must either include it as a dependency or override the `__escaped__` helper as outlined in the [Advanced Customizations](advanced.htmls) section.

## Your First Template

Here is a simple example of how a Handlebars string can be compiled into an EEx string and evaluated using bindings:

```elixir
"{{the_one_true_faith}} is the only religion that delivers the goods."
|> Zappa.compile!()
|> EEx.eval_string(the_one_true_faith: "Music")
|> IO.puts()
# "Music is the only religion that delivers the goods."
```

"Bindings" are variables that are passed to the EEx templates. They are passed as a keyword list; if you are working with maps, you will have to convert the data structure to a keyword list before using it with the EEx functions.  See the next example.

## Working with Maps

If you are new to EEx, you might find it strange that it does not rely on maps and their simple key/value structure that is probably familiar to you from any number of other programming languages.  You may have variables provided to you as a map (e.g. from decoded JSON), but you need to convert it to a keyword list to make it work with EEx. 

```elixir
bindings = "#{__DIR__}/support/templates/willie_the_pimp.json"
               |> File.read!()
               |> Jason.decode!(keys: :atoms)
               |> Map.to_list()
    
hbs = ~s"""
  Track: {{title}}
  Genres:
  {{#each genres}}
    {{@index}}: {{this}}
  {{/each}}
"""
output = hbs
         |> Zappa.compile!()
         |> EEx.eval_string(bindings)

# If we strip the whitespace, the output looks something like this:
#
# Track: Willie the Pimp 
# Genres: 0: blues rock 1: hard rock 2: jazz rock
```

Note the use of the `keys: :atoms` option in our JSON decoding: that helps us avoid errors later when we convert the map to a keyword list. If you forget to do this, you might encounter `CaseClauseError` when you attempt to evaluate your `EEx`.


## Working with Files

Most often, you will probably want to save the output of the compiling operation: this will result in better performance.


Loading a template from a file, then compiling it to EEx:
```elixir
# Convert the file from Handlebars to EEx:
eex_template =
      "/path/to/templates/my_.hbs"
      |> File.read!()
      |> Zappa.compile!()
# Save the converted file
File.write!("/path/to/templates/my.eex", eex_template)

# Evaluate the EEx file using the given bindings:
EEx.eval_file("sample.eex", bar: "baz")

```

```elixir
handlebars = ~s"""
Music is the only religion that delivers the goods.

Modern Americans behave as if intelligence were some sort of hideous deformity.

Republicans stand for raw, unbridled evil and greed and ignorance smothered in balloons and ribbons.
"""
```

## Registering Helper Functions