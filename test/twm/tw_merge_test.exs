defmodule Twm.TwMergeTest do
  use ExUnit.Case, async: true

  describe "merge function" do
    test "merges conflicting mix-blend classes" do
      assert Twm.merge("mix-blend-normal mix-blend-multiply") == "mix-blend-multiply"
    end

    test "merges conflicting height classes" do
      assert Twm.merge("h-10 h-min") == "h-min"
    end

    test "preserves non-conflicting stroke classes" do
      assert Twm.merge("stroke-black stroke-1") == "stroke-black stroke-1"
    end

    test "merges conflicting stroke width classes" do
      assert Twm.merge("stroke-2 stroke-[3]") == "stroke-[3]"
    end

    test "preserves non-conflicting outline classes" do
      assert Twm.merge("outline-black outline-1") == "outline-black outline-1"
    end

    test "merges conflicting grayscale classes" do
      assert Twm.merge("grayscale-0 grayscale-[50%]") == "grayscale-[50%]"
    end

    test "merges conflicting grow classes" do
      assert Twm.merge("grow grow-[2]") == "grow-[2]"
    end

    test "handles complex nested array input with grow classes" do
      assert Twm.merge(["grow", [nil, false, [["grow-[2]"]]]]) == "grow-[2]"
    end
  end

  describe "edge cases" do
    test "handles empty string input" do
      assert Twm.merge("") == ""
    end

    test "handles single class" do
      assert Twm.merge("px-4") == "px-4"
    end

    test "handles multiple spaces between classes" do
      assert Twm.merge("px-2   px-4") == "px-4"
    end

    test "handles list input with strings" do
      assert Twm.merge(["px-2", "px-4"]) == "px-4"
    end

    test "handles nested array structures" do
      assert Twm.merge(["px-2", ["py-1", ["px-4"]]]) == "py-1 px-4"
    end

    test "filters out nil and false values in arrays" do
      assert Twm.merge(["px-2", nil, false, "px-4"]) == "px-4"
    end
  end
end
