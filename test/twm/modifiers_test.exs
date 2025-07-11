defmodule Twm.ModifiersTest do
  use ExUnit.Case, async: true

  describe "conflicts across prefix modifiers" do
    test "basic hover modifier conflicts" do
      assert Twm.merge("hover:block hover:inline") == "hover:inline"
    end

    test "nested modifiers don't conflict when different" do
      assert Twm.merge("hover:block hover:focus:inline") == "hover:block hover:focus:inline"
    end

    test "complex nested modifier conflicts" do
      assert Twm.merge("hover:block hover:focus:inline focus:hover:inline") ==
               "hover:block focus:hover:inline"
    end

    test "focus-within modifier conflicts" do
      assert Twm.merge("focus-within:inline focus-within:block") == "focus-within:block"
    end

    test "merges hover and focus classes correctly" do
      assert Twm.merge("right-0 inset-0") ==
               "inset-0"

      assert Twm.merge("hover:right-0 hover:inset-0") ==
               "hover:inset-0"

      assert Twm.merge("hover:right-0 focus:inset-0") ==
               "hover:right-0 focus:inset-0"

      assert Twm.merge("hover:focus:right-0 focus:hover:inset-0") ==
               "focus:hover:inset-0"
    end
  end

  describe "conflicts across postfix modifiers" do
    test "text size with line height conflicts" do
      assert Twm.merge("text-lg/7 text-lg/8") == "text-lg/8"
    end

    test "text size and leading don't conflict when different" do
      assert Twm.merge("text-lg/none leading-9") == "text-lg/none leading-9"
    end

    test "leading conflicts with text size line height" do
      assert Twm.merge("leading-9 text-lg/none") == "text-lg/none"
    end

    test "width conflicts" do
      assert Twm.merge("w-full w-1/2") == "w-1/2"
    end

    test "custom configuration postfix modifiers" do
      config =
        Twm.Config.new(
          theme: [],
          class_groups: [
            foo: ["foo-1/2", "foo-2/3"],
            bar: ["bar-1", "bar-2"],
            baz: ["baz-1", "baz-2"]
          ],
          conflicting_class_groups: [],
          conflicting_class_group_modifiers: [
            baz: ["bar"]
          ],
          order_sensitive_modifiers: []
        )

      assert Twm.merge("foo-1/2 foo-2/3", config) == "foo-2/3"
      assert Twm.merge("bar-1 bar-2", config) == "bar-2"
      assert Twm.merge("bar-1 baz-1", config) == "bar-1 baz-1"
      assert Twm.merge("bar-1/2 bar-2", config) == "bar-2"
      assert Twm.merge("bar-2 bar-1/2", config) == "bar-1/2"
      assert Twm.merge("bar-1 baz-1/2", config) == "baz-1/2"
    end
  end

  describe "sorts modifiers correctly" do
    test "basic modifier sorting" do
      assert Twm.merge("c:d:e:block d:c:e:inline") == "d:c:e:inline"
    end

    test "wildcard before modifier sorting" do
      assert Twm.merge("*:before:block *:before:inline") == "*:before:inline"
    end

    test "different wildcard modifier order preservation" do
      assert Twm.merge("*:before:block before:*:inline") == "*:before:block before:*:inline"
    end

    test "complex wildcard modifier sorting" do
      assert Twm.merge("x:y:*:z:block y:x:*:z:inline") == "y:x:*:z:inline"
    end
  end

  describe "sorts modifiers correctly according to orderSensitiveModifiers" do
    test "custom order sensitive modifiers" do
      config =
        Twm.Config.new(
          cache_size: 10,
          theme: [],
          class_groups: [
            foo: ["foo-1", "foo-2"]
          ],
          conflicting_class_groups: [],
          conflicting_class_group_modifiers: [],
          order_sensitive_modifiers: ["a", "b"]
        )

      assert Twm.merge("c:d:e:foo-1 d:c:e:foo-2", config) == "d:c:e:foo-2"
      assert Twm.merge("a:b:foo-1 a:b:foo-2", config) == "a:b:foo-2"
      assert Twm.merge("a:b:foo-1 b:a:foo-2", config) == "a:b:foo-1 b:a:foo-2"
      assert Twm.merge("x:y:a:z:foo-1 y:x:a:z:foo-2", config) == "y:x:a:z:foo-2"
    end
  end
end
