defmodule Twm.WonkyInputsTest do
  use ExUnit.Case, async: false

  describe "handles wonky inputs" do
    test "handles leading whitespace" do
      assert Twm.merge(" block") == "block"
    end

    test "handles trailing whitespace" do
      assert Twm.merge("block ") == "block"
    end

    test "handles leading and trailing whitespace" do
      assert Twm.merge(" block ") == "block"
    end

    test "handles multiple spaces between classes" do
      assert Twm.merge("  block  px-2     py-4  ") == "block px-2 py-4"
    end

    test "handles multiple arguments with spaces" do
      assert Twm.merge(["  block  px-2", " ", "     py-4  "]) == "block px-2 py-4"
    end

    test "handles newlines in classes" do
      assert Twm.merge("block\npx-2") == "block px-2"
    end

    test "handles leading and trailing newlines" do
      assert Twm.merge("\nblock\npx-2\n") == "block px-2"
    end

    test "handles complex whitespace with newlines" do
      assert Twm.merge("  block\n        \n        px-2   \n          py-4  ") ==
               "block px-2 py-4"
    end

    test "handles carriage returns and newlines" do
      assert Twm.merge("\r  block\n\r        \n        px-2   \n          py-4  ") ==
               "block px-2 py-4"
    end
  end
end
