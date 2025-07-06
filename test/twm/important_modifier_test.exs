defmodule Twm.ImportantModifierTest do
  use ExUnit.Case, async: true

  describe "merges tailwind classes with important modifier correctly" do
    test "handles exclamation mark after class name" do
      assert Twm.merge("font-medium! font-bold!") == "font-bold!"
    end

    test "handles mix of important and non-important classes" do
      assert Twm.merge("font-medium! font-bold! font-thin") == "font-bold! font-thin"
    end

    test "handles important positioning classes" do
      assert Twm.merge("right-2! -inset-x-px!") == "-inset-x-px!"
    end

    test "handles important focus modifiers" do
      assert Twm.merge("focus:inline! focus:block!") == "focus:block!"
    end

    test "handles important arbitrary values" do
      assert Twm.merge("[--my-var:20px]! [--my-var:30px]!") == "[--my-var:30px]!"
    end

    # Tailwind CSS v3 legacy syntax tests
    test "handles legacy important syntax with exclamation before class" do
      assert Twm.merge("font-medium! !font-bold") == "!font-bold"
    end

    test "handles legacy important syntax both classes with exclamation before" do
      assert Twm.merge("!font-medium !font-bold") == "!font-bold"
    end

    test "handles legacy important with mix of important and non-important" do
      assert Twm.merge("!font-medium !font-bold font-thin") == "!font-bold font-thin"
    end

    test "handles legacy important positioning classes" do
      assert Twm.merge("!right-2 !-inset-x-px") == "!-inset-x-px"
    end

    test "handles legacy important focus modifiers" do
      assert Twm.merge("focus:!inline focus:!block") == "focus:!block"
    end

    test "handles legacy important arbitrary values" do
      assert Twm.merge("![--my-var:20px] ![--my-var:30px]") == "![--my-var:30px]"
    end
  end
end
