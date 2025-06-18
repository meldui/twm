defmodule Twm.ArbitraryValuesTest do
  use ExUnit.Case, async: true

  describe "merge/1 with simple arbitrary value conflicts" do
    test "handles simple conflicts with arbitrary values correctly" do
      assert Twm.merge("m-[2px] m-[10px]") == "m-[10px]"

      assert Twm.merge(
               "m-[2px] m-[11svmin] m-[12in] m-[13lvi] m-[14vb] m-[15vmax] m-[16mm] m-[17%] m-[18em] m-[19px] m-[10dvh]"
             ) ==
               "m-[10dvh]"

      assert Twm.merge("h-[10px] h-[11cqw] h-[12cqh] h-[13cqi] h-[14cqb] h-[15cqmin] h-[16cqmax]") ==
               "h-[16cqmax]"

      assert Twm.merge("my-[2px] m-[10rem]") == "m-[10rem]"

      assert Twm.merge("m-[2px] m-[calc(100%-var(--arbitrary))]") ==
               "m-[calc(100%-var(--arbitrary))]"

      assert Twm.merge("m-[2px] m-[length:var(--mystery-var)]") == "m-[length:var(--mystery-var)]"

      assert Twm.merge("p-[2px] p-[10px]") == "p-[10px]"

      assert Twm.merge("w-[100px] w-[200px]") == "w-[200px]"
    end

    test "handles value 0 correctly" do
      assert Twm.merge("min-h-[0.5px] min-h-[0]") == "min-h-[0]"

      assert Twm.merge("h-[0.5px] h-[0]") == "h-[0]"

      assert Twm.merge("w-[0.5px] w-[0]") == "w-[0]"
    end
  end

  describe "merge/1 with arbitrary length conflicts with labels and modifiers" do
    test "handles arbitrary lengths with modifiers correctly" do
      assert Twm.merge("hover:m-[2px] hover:m-[length:var(--c)]") == "hover:m-[length:var(--c)]"

      assert Twm.merge("hover:focus:m-[2px] focus:hover:m-[length:var(--c)]") ==
               "focus:hover:m-[length:var(--c)]"

      assert Twm.merge("hover:p-[2px] hover:p-[length:var(--c)]") == "hover:p-[length:var(--c)]"

      assert Twm.merge("sm:h-[100px] sm:h-[200px]") == "sm:h-[200px]"
    end
  end

  describe "merge/1 with complex arbitrary value conflicts" do
    test "handles complex arbitrary value conflicts correctly" do
      assert Twm.merge("grid-rows-[1fr,auto] grid-rows-2") == "grid-rows-2"
      assert Twm.merge("grid-rows-[repeat(20,minmax(0,1fr))] grid-rows-3") == "grid-rows-3"

      assert Twm.merge("w-[calc(100%-2rem)] w-[calc(50%+1rem)]") == "w-[calc(50%+1rem)]"

      assert Twm.merge("h-[theme(spacing.4)] h-[theme(spacing.8)]") == "h-[theme(spacing.8)]"
    end
  end

  describe "merge/1 with ambiguous arbitrary values" do
    test "handles ambiguous arbitrary values correctly" do
      assert Twm.merge("mt-2 mt-[calc(theme(fontSize.4xl)/1.125)]") ==
               "mt-[calc(theme(fontSize.4xl)/1.125)]"

      assert Twm.merge("p-2 p-[calc(theme(fontSize.4xl)/1.125)_10px]") ==
               "p-[calc(theme(fontSize.4xl)/1.125)_10px]"

      assert Twm.merge("mt-2 mt-[length:theme(someScale.someValue)]") ==
               "mt-[length:theme(someScale.someValue)]"

      assert Twm.merge("mt-2 mt-[theme(someScale.someValue)]") ==
               "mt-[theme(someScale.someValue)]"

      assert Twm.merge("w-64 w-[length:theme(someScale.someValue)]") ==
               "w-[length:theme(someScale.someValue)]"

      assert Twm.merge("h-32 h-[calc(theme(fontSize.4xl)/1.125)]") ==
               "h-[calc(theme(fontSize.4xl)/1.125)]"
    end
  end

  describe "merge/1 with spacing and sizing combinations" do
    test "handles spacing and sizing conflicts correctly" do
      assert Twm.merge("m-4 m-[2px] m-8 m-[10px]") == "m-[10px]"

      assert Twm.merge("p-2 p-[1rem] pb-4 p-[2rem]") == "p-[2rem]"

      assert Twm.merge("w-32 w-[200px] h-16 h-[100px]") == "w-[200px] h-[100px]"
    end
  end

  describe "tw_merge/1 with arbitrary values" do
    test "tw_merge is an alias that handles arbitrary values" do
      assert Twm.tw_merge("m-[2px] m-[10px]") == Twm.merge("m-[2px] m-[10px]")

      assert Twm.tw_merge("hover:m-[2px] hover:m-[length:var(--c)]") ==
               Twm.merge("hover:m-[2px] hover:m-[length:var(--c)]")

      assert Twm.tw_merge("w-[100px] h-[200px] w-[300px]") ==
               Twm.merge("w-[100px] h-[200px] w-[300px]")
    end
  end

  describe "merge/1 with list input and arbitrary values" do
    test "handles arbitrary values when classes are provided as a list" do
      assert Twm.merge(["m-[2px]", "m-[10px]"]) == "m-[10px]"

      assert Twm.merge(["hover:m-[2px]", "hover:m-[length:var(--c)]"]) ==
               "hover:m-[length:var(--c)]"

      assert Twm.merge(["w-[100px]", "h-[200px]", "w-[300px]"]) ==
               "h-[200px] w-[300px]"
    end
  end

  describe "edge cases with arbitrary values" do
    test "handles empty arbitrary values" do
      assert Twm.merge("m-[] m-[10px]") == "m-[] m-[10px]"
    end

    test "handles malformed arbitrary values" do
      assert Twm.merge("m-[2px m-[10px]") == "m-[2px m-[10px]"
      assert Twm.merge("m-2px] m-[10px]") == "m-2px] m-[10px]"
    end

    test "handles mixed arbitrary and regular values" do
      assert Twm.merge("m-4 m-[2px] m-8 m-[10px]") == "m-[10px]"
      assert Twm.merge("p-2 p-[1rem] pb-4 p-[2rem]") == "p-[2rem]"
      assert Twm.merge("w-32 w-[200px] h-16 h-[100px]") == "w-[200px] h-[100px]"
    end

    test "handles multiple modifiers with arbitrary values" do
      assert Twm.merge("sm:hover:focus:m-[2px] sm:hover:focus:m-[10px]") ==
               "sm:hover:focus:m-[10px]"
    end

    test "handles arbitrary values with special characters" do
      assert Twm.merge("m-[calc(100%-2rem)] m-[calc(50%+1rem)]") ==
               "m-[calc(50%+1rem)]"

      assert Twm.merge("w-[calc(100vw-2rem)] w-[calc(100vw-4rem)]") ==
               "w-[calc(100vw-4rem)]"
    end

    test "handles arbitrary values with CSS variables" do
      assert Twm.merge("m-[var(--spacing-1)] m-[var(--spacing-2)]") ==
               "m-[var(--spacing-2)]"

      assert Twm.merge("w-[var(--width-1)] w-[var(--width-2)]") ==
               "w-[var(--width-2)]"
    end

    test "handles arbitrary values with theme functions" do
      assert Twm.merge("m-[theme(spacing.4)] m-[theme(spacing.8)]") ==
               "m-[theme(spacing.8)]"

      assert Twm.merge("h-[theme(spacing.4)] h-[theme(spacing.8)]") ==
               "h-[theme(spacing.8)]"
    end
  end
end
