defmodule Twm.ClassGroupConflictsTest do
  use ExUnit.Case, async: true

  describe "merges classes from same group correctly" do
    test "overflow-x classes" do
      assert Twm.merge("overflow-x-auto overflow-x-hidden") == "overflow-x-hidden"
    end

    test "basis classes" do
      assert Twm.merge("basis-full basis-auto") == "basis-auto"
    end

    test "width classes" do
      assert Twm.merge("w-full w-fit") == "w-fit"
    end

    test "multiple overflow-x classes" do
      assert Twm.merge("overflow-x-auto overflow-x-hidden overflow-x-scroll") ==
               "overflow-x-scroll"
    end

    test "hover overflow-x with base overflow-x" do
      assert Twm.merge("overflow-x-auto hover:overflow-x-hidden overflow-x-scroll") ==
               "hover:overflow-x-hidden overflow-x-scroll"
    end

    test "hover overflow-x conflicts with hover overflow-x" do
      assert Twm.merge(
               "overflow-x-auto hover:overflow-x-hidden hover:overflow-x-auto overflow-x-scroll"
             ) ==
               "hover:overflow-x-auto overflow-x-scroll"
    end

    test "col-span classes" do
      assert Twm.merge("col-span-1 col-span-full") == "col-span-full"
    end

    test "mixed gap and basis classes" do
      assert Twm.merge("gap-2 gap-px basis-px basis-3") == "gap-px basis-3"
    end
  end

  describe "merges classes from Font Variant Numeric section correctly" do
    test "non-conflicting font variant numeric classes" do
      assert Twm.merge("lining-nums tabular-nums diagonal-fractions") ==
               "lining-nums tabular-nums diagonal-fractions"
    end

    test "normal-nums conflicts with lining-nums" do
      assert Twm.merge("normal-nums tabular-nums diagonal-fractions") ==
               "tabular-nums diagonal-fractions"
    end

    test "normal-nums overrides all font variant numeric classes" do
      assert Twm.merge("tabular-nums diagonal-fractions normal-nums") == "normal-nums"
    end

    test "proportional-nums overrides tabular-nums" do
      assert Twm.merge("tabular-nums proportional-nums") == "proportional-nums"
    end
  end
end
