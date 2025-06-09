defmodule Twm.ArbitraryVariantsTest do
  use ExUnit.Case

  import Twm, only: [merge: 1]

  describe "basic arbitrary variants" do
    test "merges basic arbitrary variants" do
      assert merge("[p]:underline [p]:line-through") == "[p]:line-through"
    end

    test "merges arbitrary variants with selector syntax" do
      assert merge("[&>*]:underline [&>*]:line-through") == "[&>*]:line-through"
    end

    test "preserves different arbitrary variants" do
      assert merge("[&>*]:underline [&>*]:line-through [&_div]:line-through") ==
               "[&>*]:line-through [&_div]:line-through"
    end

    test "merges supports queries" do
      assert merge("supports-[display:grid]:flex supports-[display:grid]:grid") ==
               "supports-[display:grid]:grid"
    end
  end

  describe "arbitrary variants with modifiers" do
    test "merges arbitrary variants with multiple modifiers" do
      assert merge("dark:lg:hover:[&>*]:underline dark:lg:hover:[&>*]:line-through") ==
               "dark:lg:hover:[&>*]:line-through"
    end

    test "handles different modifier orders" do
      assert merge("dark:lg:hover:[&>*]:underline dark:hover:lg:[&>*]:line-through") ==
               "dark:hover:lg:[&>*]:line-through"
    end

    test "preserves different modifier positions relative to arbitrary variants" do
      assert merge("hover:[&>*]:underline [&>*]:hover:line-through") ==
               "hover:[&>*]:underline [&>*]:hover:line-through"
    end

    test "handles complex modifier combinations" do
      result =
        merge(
          "hover:dark:[&>*]:underline dark:hover:[&>*]:underline dark:[&>*]:hover:line-through"
        )

      assert result == "dark:hover:[&>*]:underline dark:[&>*]:hover:line-through"
    end
  end

  describe "arbitrary variants with complex syntax" do
    test "handles complex media query syntax" do
      result =
        merge(
          "[@media_screen{@media(hover:hover)}]:underline [@media_screen{@media(hover:hover)}]:line-through"
        )

      assert result == "[@media_screen{@media(hover:hover)}]:line-through"
    end

    test "handles complex media query syntax with modifiers" do
      result =
        merge(
          "hover:[@media_screen{@media(hover:hover)}]:underline hover:[@media_screen{@media(hover:hover)}]:line-through"
        )

      assert result == "hover:[@media_screen{@media(hover:hover)}]:line-through"
    end
  end

  describe "arbitrary variants with attribute selectors" do
    test "merges variants with attribute selectors" do
      assert merge("[&[data-open]]:underline [&[data-open]]:line-through") ==
               "[&[data-open]]:line-through"
    end

    test "handles multiple attribute selectors with complex syntax" do
      result =
        merge(
          "[&[data-foo][data-bar]:not([data-baz])]:underline [&[data-foo][data-bar]:not([data-baz])]:line-through"
        )

      assert result == "[&[data-foo][data-bar]:not([data-baz])]:line-through"
    end
  end

  describe "multiple arbitrary variants" do
    test "merges multiple arbitrary variants when identical" do
      assert merge("[&>*]:[&_div]:underline [&>*]:[&_div]:line-through") ==
               "[&>*]:[&_div]:line-through"
    end

    test "preserves different multiple arbitrary variants" do
      assert merge("[&>*]:[&_div]:underline [&_div]:[&>*]:line-through") ==
               "[&>*]:[&_div]:underline [&_div]:[&>*]:line-through"
    end

    test "handles complex multiple variants with modifiers" do
      result =
        merge(
          "hover:dark:[&>*]:focus:disabled:[&_div]:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"
        )

      assert result == "dark:hover:[&>*]:disabled:focus:[&_div]:line-through"
    end

    test "preserves different modifier arrangements in multiple variants" do
      result =
        merge(
          "hover:dark:[&>*]:focus:[&_div]:disabled:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"
        )

      expected =
        "hover:dark:[&>*]:focus:[&_div]:disabled:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"

      assert result == expected
    end
  end

  describe "arbitrary variants with arbitrary properties" do
    test "merges arbitrary variants with arbitrary properties" do
      assert merge("[&>*]:[color:red] [&>*]:[color:blue]") == "[&>*]:[color:blue]"
    end

    test "handles complex arbitrary variants with arbitrary properties and modifiers" do
      result =
        merge(
          "[&[data-foo][data-bar]:not([data-baz])]:nod:noa:[color:red] [&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]"
        )

      assert result == "[&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]"
    end
  end
end
