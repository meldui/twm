defmodule Twm.NegativeValuesTest do
  use ExUnit.Case, async: true

  describe "handles negative value conflicts correctly" do
    test "negative margin conflicts" do
      assert Twm.merge("-m-2 -m-5") == "-m-5"
    end

    test "negative top positioning conflicts" do
      assert Twm.merge("-top-12 -top-2000") == "-top-2000"
    end
  end

  describe "handles conflicts between positive and negative values correctly" do
    test "negative margin conflicts with positive margin" do
      assert Twm.merge("-m-2 m-auto") == "m-auto"
    end

    test "positive top conflicts with negative top" do
      assert Twm.merge("top-12 -top-69") == "-top-69"
    end
  end

  describe "handles conflicts across groups with negative values correctly" do
    test "negative right conflicts with inset-x" do
      assert Twm.merge("-right-1 inset-x-1") == "inset-x-1"
    end

    # TODO: This test currently tests the existing behavior but should be updated
    # when modifier normalization is implemented. The implementation should treat
    # "hover:focus:" and "focus:hover:" as equivalent modifier combinations that
    # should conflict, with the expected result being "focus:hover:inset-x-1".
    test "complex modifier negative right conflicts with inset-x" do
      assert Twm.merge("hover:focus:-right-1 focus:hover:inset-x-1") == "focus:hover:inset-x-1"
    end
  end
end
