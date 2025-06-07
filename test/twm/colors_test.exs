defmodule Twm.ColorsTest do
  use ExUnit.Case
  doctest Twm

  describe "handles color conflicts properly" do
    test "resolves basic color conflicts" do
      assert Twm.merge("bg-grey-5 bg-hotpink") == "bg-hotpink"
    end

    test "resolves color conflicts with modifiers" do
      assert Twm.merge("hover:bg-grey-5 hover:bg-hotpink") == "hover:bg-hotpink"
    end

    test "preserves different color properties with arbitrary values" do
      assert Twm.merge("stroke-[hsl(350_80%_0%)] stroke-[10px]") == 
             "stroke-[hsl(350_80%_0%)] stroke-[10px]"
    end
  end
end