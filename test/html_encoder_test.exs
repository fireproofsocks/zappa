defmodule Zappa.HtmlEncoderTest do
  use Zappa.TestCase

  alias Zappa.HtmlEncoder

  describe "encode/1" do
    test "encodes strings without special characters" do
      assert "foo" == HtmlEncoder.encode("foo")
    end

    test "encodes strings with special characters" do
      assert "&lt;a href=&quot;/seduction?sex=robot&amp;status=on&quot; class=&apos;hoover&apos;&gt;Plook Me!&lt;/a&gt;" ==
               HtmlEncoder.encode(
                 ~S|<a href="/seduction?sex=robot&status=on" class='hoover'>Plook Me!</a>|
               )
    end

    test "encodes integers" do
      assert "69" = HtmlEncoder.encode(69)
    end

    test "encodes floats" do
      assert "99.1" = HtmlEncoder.encode(99.1)
    end

    test "encodes booleans" do
      assert "true" = HtmlEncoder.encode(true)
    end

    test "encodes lists" do
      assert is_binary(HtmlEncoder.encode(["who", "gives", "a"]))
    end

    test "encodes maps" do
      assert is_binary(HtmlEncoder.encode(%{}))
    end
  end
end
