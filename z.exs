tpl = ~s"""
The start...
<%= Enum.with_index(list)
|> Enum.map(fn {x, index} ->
    case x do
      {k, v} -> %>
        "<%= x %>: @index: <%= index %>"
    <% x -> %>
          "<%= x %>: @index: <%= index %>"
    <% end %>
<% end) %>
...The end.
"""

# This works:
_tpl = ~s"""
The start...
<%= Enum.with_index(list)
|> Enum.map(fn {x, index} -> %>
      <%= x %>: @index: <%= index %>
<% end) %>
...The end.
"""


#Enum.with_index(m)
#|> Enum.each(fn {x, index} ->
#  case x do
#    x when is_tuple(x) ->
#      {k, v} = x
#      IO.puts("#{k}: #{v} @index:#{index}")
#
#    x ->
#      IO.puts("#{x} @index:#{index}")
#  end
#end)

out = EEx.eval_string(tpl, [list: ["a", "b", "c"]])
IO.puts(out)