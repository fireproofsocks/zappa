defmodule ZappaTest do
  use ExUnit.Case
  doctest Zappa

  test "greets the world" do
    assert Zappa.hello() == :world
  end
end
