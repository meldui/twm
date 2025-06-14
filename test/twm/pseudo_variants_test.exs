defmodule Twm.PseudoVariantsTest do
  use ExUnit.Case, async: false

  describe "pseudo variants conflicts" do
    test "handles pseudo variants conflicts properly" do
      assert Twm.merge("empty:p-2 empty:p-3") == "empty:p-3"
      assert Twm.merge("hover:empty:p-2 hover:empty:p-3") == "hover:empty:p-3"
      assert Twm.merge("read-only:p-2 read-only:p-3") == "read-only:p-3"
    end
  end

  describe "pseudo variant group conflicts" do
    test "handles pseudo variant group conflicts properly" do
      assert Twm.merge("group-empty:p-2 group-empty:p-3") == "group-empty:p-3"
      assert Twm.merge("peer-empty:p-2 peer-empty:p-3") == "peer-empty:p-3"
      assert Twm.merge("group-empty:p-2 peer-empty:p-3") == "group-empty:p-2 peer-empty:p-3"
      assert Twm.merge("hover:group-empty:p-2 hover:group-empty:p-3") == "hover:group-empty:p-3"
      assert Twm.merge("group-read-only:p-2 group-read-only:p-3") == "group-read-only:p-3"
    end
  end
end
