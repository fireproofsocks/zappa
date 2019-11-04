# Conversion to EEx

How exactly do we convert a Handlebars template to an equivalent EEx template?
The use-cases are outlined below.

Review [https://hexdocs.pm/phoenix/templates.html](https://hexdocs.pm/phoenix/templates.html)

## Simple Placeholders:

Handlebars:
```
<h1>{{title}}</h1>
<p>{{content}}</p>
```

EEx:
```eex
<h1><%= HtmlEntities.encode(title) %></h1>
<p><%= HtmlEntities.encode(content) %></p>
```

## Unescaped

Handlebars:
```
<h1>{{{title}}}</h1>
<p>{{{content}}}</p>
```

EEx:
```eex
<h1><%= title %></h1>
<p><%= content %></p>
```



## Blocks

Handlebars:
```
<ul class="people_list">
  {{#each people}}
    <li>{{this}}</li>
  {{/each}}
</ul>
```

EEx:
```eex
<ul class="people_list">
  <%= for this <- people do %>
    <li><%= HtmlEntities.encode(this) %></li>
  <% end %>
</ul>
```

## Comments

Handlebars:
```
{{! Comments - they are discarded from source }}
```

EEx:
```eex
<%# Comments - they are discarded from source %>
```