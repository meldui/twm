defmodule Twm.PrefixesTest do
  use ExUnit.Case

  describe "prefix working correctly" do
    test "merges prefixed classes correctly" do
      tw_merge = Twm.extend_tailwind_merge(prefix: "tw")

      assert tw_merge.("tw:block tw:hidden") == "tw:hidden"
      assert tw_merge.("block hidden") == "block hidden"
    end

    test "merges prefixed padding classes correctly" do
      tw_merge = Twm.extend_tailwind_merge(prefix: "tw")

      assert tw_merge.("tw:p-3 tw:p-2") == "tw:p-2"
      assert tw_merge.("p-3 p-2") == "p-3 p-2"
    end

    test "merges prefixed important classes correctly" do
      tw_merge = Twm.extend_tailwind_merge(prefix: "tw")

      assert tw_merge.("tw:right-0! tw:inset-0!") == "tw:inset-0!"
    end

    test "merges prefixed hover and focus classes correctly" do
      # tw_merge = Twm.extend_tailwind_merge(%{prefix: ""})

      assert Twm.merge("right-0! inset-0!") ==
               "inset-0!"

      assert Twm.merge("hover:focus:right-0! focus:hover:inset-0!") == "focus:hover:inset-0!"
    end
  end
end
