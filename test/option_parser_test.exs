defmodule Zappa.OptionParserTest do
  use Zappa.TestCase

  alias Zappa.OptionParser

  describe "split/1" do
    test "split mixed arguments and keys with quoted values" do
      {args, kwargs} = OptionParser.split("muffin 'man' spoon='chrome' kitchen=lab")
      assert args == [%{quoted?: false, value: "muffin"}, %{quoted?: true, value: "man"}]
      assert kwargs == %{kitchen: "lab", spoon: "chrome"}
    end

    test "understands non quoted values" do
      {_args, kwargs} = OptionParser.split("church=appliantology  contest=wet-t-shirt")
      assert kwargs == %{church: "appliantology", contest: "wet-t-shirt"}
    end

    test "remove escapes from spaces and quotes when we're not in a quote" do
      {args, _kwargs} = OptionParser.split("bungles \\'")
      assert args == [%{quoted?: false, value: "bungles"}, %{quoted?: false, value: "'"}]
    end

    test "raises when quotes are not matched" do
      assert_raise RuntimeError, fn -> OptionParser.split("muffin's") end
    end
  end

  describe "split_block/1" do
    test "missing variable yield error" do
      assert {:error, _} = OptionParser.split_block("")
    end

    test "invalid variable characters yields error" do
      assert {:error, _} = OptionParser.split_block("69$money")
    end

    test "variable only yields default values for iterator and index" do
      assert {:ok, {"prophets", "this", "index___helper"}} = OptionParser.split_block("prophets")
    end

    test "block syntax specifies iterator only yields default index" do
      assert {:ok, {"girls", "catholicGirl", "index___helper"}} =
               OptionParser.split_block("girls as |catholicGirl|")
    end

    test "block syntax specifies custom iterator and index" do
      assert {:ok, {"brave_new_world", "brainPolice", "IamGonnaDie"}} =
               OptionParser.split_block("brave_new_world as |brainPolice, IamGonnaDie|")
    end
  end
end
