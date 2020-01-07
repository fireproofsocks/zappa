defmodule Zappa.Helpers.Log do
  @moduledoc false
  # This module implements the [log](https://handlebarsjs.com/guide/builtin-helpers.html#log) helper function.
  # See https://handlebarsjs.com/examples/builtin-helper-log-loglevel.html
  # The log helper allows for logging of context state while **executing** a template (not while compiling it), so the
  # implementation returns an EEx expression that will evaluate when the template is evaluated.
  # `{{log "debug logging" level="debug"}}`

  alias Zappa.Tag

  @spec parse(Tag.t()) :: {:error, String.t}
  def parse(%Tag{args: []}) do
    {:error, "Log helper requires options, e.g. {{log 'some message'}}"}
  end

  def parse(%Tag{args: args, kwargs: kwargs}) do
    statements =
    Enum.map(args, fn x -> statement(x, kwargs) end)
    |> Enum.join("")

    {:ok, statements}
  end


  defp statement(%{value: value, quoted?: true}, %{level: level}) do
    ~s/<% Logger.#{level}("#{value}") %>/
  end

  defp statement(%{value: value, quoted?: false}, %{level: level}) do
    ~s/<% Logger.#{level}(#{value}) %>/
  end

  defp statement(%{value: value, quoted?: true}, _kwargs) do
    ~s/<% Logger.info("#{value}") %>/
  end

  defp statement(%{value: value, quoted?: false}, _kwargs) do
    ~s/<% Logger.info(#{value}) %>/
  end
end
