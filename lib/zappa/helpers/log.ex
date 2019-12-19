defmodule Zappa.Helpers.Log do
  @moduledoc """
  This module implements the [log](https://handlebarsjs.com/guide/builtin-helpers.html#log) helper function.
  The log helper allows for logging of context state while **executing** a template (not while compiling it), so the
  implementation returns an EEx expression that will evaluate when the template is evaluated.

  TODO: argument parser to support n inputs and keyword arguments, e.g.
  `{{log "debug logging" level="debug"}}`
  """

  alias Zappa.Tag

  def parse_log(%Tag{options: ""}) do
    {:error, "Log helper requires options, e.g. {{log 'some message'}}"}
  end

  def parse_log(tag) do
    {:ok, "<% Logger.info(#{tag.options}) %>"}
  end
end
