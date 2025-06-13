defmodule Twm.NonConflictingClassesTest do
  use ExUnit.Case

  describe "merges non-conflicting classes correctly" do
    test "merges border classes with opacity" do
      assert Twm.merge("border-t border-white/10") == "border-t border-white/10"
    end

    test "merges border classes without opacity" do
      assert Twm.merge("border-t border-white") == "border-t border-white"
    end

    test "merges text size and color classes" do
      assert Twm.merge("text-3.5xl text-black") == "text-3.5xl text-black"
    end
  end
end
