defmodule Twm.PerSideBorderColorsTest do
  use ExUnit.Case

  describe "merges classes with per-side border colors correctly" do
    test "merges border-t colors with same side" do
      assert Twm.merge("border-t-some-blue border-t-other-blue") == "border-t-other-blue"
    end

    test "merges border-t color with general border color" do
      assert Twm.merge("border-t-some-blue border-some-blue") == "border-some-blue"
    end

    test "preserves both border-s and general border colors" do
      assert Twm.merge("border-some-blue border-s-some-blue") ==
               "border-some-blue border-s-some-blue"
    end

    test "general border color overrides border-e color" do
      assert Twm.merge("border-e-some-blue border-some-blue") == "border-some-blue"
    end
  end
end
