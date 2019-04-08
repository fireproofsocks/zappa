defmodule Zappa do
  @moduledoc """
  Documentation for Zappa.
  """

  require Logger

  @doc """
  Compiles a handlebars template to EEx

  ## Examples

      iex> Zappa.compile_template()
      :world

  """
  def compile_template(template) do
    # TODO
    template
  end

  def parse(template, values, helpers) do
    Logger.debug(template)
    Logger.debug(values)
    Logger.debug(helpers)
    template
  end

  def register_helper(tag, callback) do

  end

  @doc """
  Hello world.

  ## Examples

      iex> Zappa.hello()
      :world

  """
  def hello do
    :world
  end
end
