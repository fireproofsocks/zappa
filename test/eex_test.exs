defmodule Zappa.EExTest do
  @moduledoc """
  My studies of embedded elixir...
  """
  use ExUnit.Case

  describe "evaluating strings" do
    # https://hexdocs.pm/eex/EEx.html
    test "basic usage uses a list" do
      assert "foo baz" == EEx.eval_string("foo <%= bar %>", bar: "baz")
    end

    test "basic usage with map requires conversion" do
      assert "foo baz" == EEx.eval_string("foo <%= bar %>", Map.to_list(%{bar: "baz"}))
    end
  end
end
