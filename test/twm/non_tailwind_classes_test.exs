defmodule Twm.NonTailwindClassesTest do
  use ExUnit.Case

  describe "does not alter non-tailwind classes" do
    test "preserves non-tailwind class with conflicting tailwind classes" do
      assert Twm.merge("non-tailwind-class inline block") == "non-tailwind-class block"
    end

    test "preserves non-tailwind class with number suffix" do
      assert Twm.merge("inline block inline-1") == "block inline-1"
    end

    test "preserves non-tailwind class with prefix" do
      assert Twm.merge("inline block i-inline") == "block i-inline"
    end

    test "preserves non-tailwind classes with focus modifier" do
      assert Twm.merge("focus:inline focus:block focus:inline-1") == "focus:block focus:inline-1"
    end
  end
end