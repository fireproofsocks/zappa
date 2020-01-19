defmodule Zappa.Helpers.LogTest do
  use Zappa.TestCase

  test "built-in log helper requires options" do
    tpl = ~s({{log}})
    assert {:error, _} = Zappa.compile(tpl)
  end

  test "default log level is info" do
    tpl = ~s({{log "something happened"}})
    output = ~s/<% Logger.info("something happened") %>/
    assert {:ok, output} == Zappa.compile(tpl)
  end

  test "log level can be set to debug" do
    tpl = ~s/{{log "something happened" level='debug'}}/
    output = ~s/<% Logger.debug("something happened") %>/
    assert {:ok, output} == Zappa.compile(tpl)
  end

  test "log can be passed multiple arguments" do
    tpl = ~s({{log "key" key "value" value}})

    output =
      ~S/<% Logger.info("key") %><% Logger.info(key) %><% Logger.info("value") %><% Logger.info(value) %>/

    assert {:ok, output} == Zappa.compile(tpl)
  end

  test "unquoted values can be logged at all levels" do
    tpl = ~s({{log brainwaves level=debug}})

    output = ~S/<% Logger.debug(brainwaves) %>/

    assert {:ok, output} == Zappa.compile(tpl)
  end
end
