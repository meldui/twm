defmodule Twm.PrefixesTest do
  use ExUnit.Case

  describe "prefix working correctly" do
    test "merges prefixed classes correctly" do
      config = Twm.Config.extend(prefix: "tw")

      assert Twm.merge("tw:block tw:hidden", config) == "tw:hidden"
      assert Twm.merge("block hidden", config) == "block hidden"
    end

    test "merges prefixed padding classes correctly" do
      config = Twm.Config.extend(prefix: "tw")

      assert Twm.merge("tw:p-3 tw:p-2", config) == "tw:p-2"
      assert Twm.merge("p-3 p-2", config) == "p-3 p-2"
    end

    test "merges prefixed important classes correctly" do
      config = Twm.Config.extend(prefix: "tw")

      assert Twm.merge("tw:right-0! tw:inset-0!", config) == "tw:inset-0!"
    end

    test "merges prefixed hover and focus classes correctly" do
      # tw_merge = Twm.extend_tailwind_merge(%{prefix: ""})

      assert Twm.merge("right-0! inset-0!") ==
               "inset-0!"

      assert Twm.merge("hover:focus:right-0! focus:hover:inset-0!") == "focus:hover:inset-0!"
    end
  end
end
