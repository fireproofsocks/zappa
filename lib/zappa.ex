defmodule Zappa do
  @moduledoc """
  Documentation for Zappa.
  """

  require Logger

  @doc """
  Compiles a handlebars template to EEx

  ## Examples

      iex> Zappa.handlebars2eex()
      :world

  """
  def handlebars2eex(template) do
    # TODO
    # Blocks... for each block |> parse_main
    # Helpers
    # Regular tags (inside a block)
    template
  end

  # Main parsing function
  def parse_main(template) do
    template
    # Strip out any existing EEx (security!)
    # raw-helper?
    # partials?
    |> parse_comments()
    |> parse_triple_braces()
    |> parse_double_braces()
  end

  def parse_double_braces(template) do
    regex = ~r/{{\s*(\p{L}*)\s*}}/u
    findings = Regex.scan(regex, template)

    Enum.reduce(findings, template, fn [full_tag, var_name], acc ->
      replacement = "<%= HtmlEntities.encode(#{var_name}) %>"
      String.replace(acc, full_tag, replacement)
    end)

  end

  def parse_triple_braces(template) do
    regex = ~r/{{{\s*(\p{L}*)\s*}}}/u
    findings = Regex.scan(regex, template)

    Enum.reduce(findings, template, fn [full_tag, var_name], acc ->
      replacement = "<%= #{var_name} %>"
      String.replace(acc, full_tag, replacement)
    end)

  end

  def parse_comments(template) do
    regex = ~r/{{!\s*(\p{L}*)\s*}}/u
    findings = Regex.scan(regex, template)

    Enum.reduce(findings, template, fn [full_tag, contents], acc ->
      replacement = "<%##{contents}%>"
      String.replace(acc, full_tag, replacement)
    end)
  end

  @doc """
  This removes all EEX tags from the input template.
  This is a security measure in case some nefarious user gets the sneaky idea to put EEX functions inside what should
  be a Handlebars template.
  """
  def replace_eex(template) do
    regex = ~r/<%.*%>/U
    Regex.scan(regex, tpl)
    |>  Enum.reduce(template, fn [x | _], acc -> String.replace(acc, x, "") end)
  end
#  def register_helper(tag, callback) do
#
#  end
#
#  def default_helpers() do
#
#  end
end
