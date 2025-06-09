defmodule Twm.Config.ThemeTest do
  use ExUnit.Case, async: true

  alias Twm.Config.Theme

  doctest Twm.Config.Theme

  describe "from_theme/1" do
    test "returns a ThemeGetter struct for string keys" do
      theme_getter = Theme.from_theme("spacing")

      assert %Theme.ThemeGetter{} = theme_getter
      assert theme_getter.key == :spacing
      assert theme_getter.is_theme_getter == true
      assert is_function(theme_getter.getter_fn, 1)
    end

    test "returns a ThemeGetter struct for atom keys" do
      theme_getter = Theme.from_theme(:color)

      assert %Theme.ThemeGetter{} = theme_getter
      assert theme_getter.key == :color
      assert theme_getter.is_theme_getter == true
      assert is_function(theme_getter.getter_fn, 1)
    end

    test "converts string keys to atoms" do
      theme_getter = Theme.from_theme("font-weight")
      assert theme_getter.key == :"font-weight"
    end

    test "handles hyphenated keys" do
      theme_getter = Theme.from_theme("drop-shadow")
      assert theme_getter.key == :"drop-shadow"
    end
  end

  describe "call_theme_getter/2" do
    test "extracts values from theme config for existing keys" do
      theme_getter = Theme.from_theme(:spacing)
      theme_config = %{spacing: ["1", "2", "4", "8"]}

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == ["1", "2", "4", "8"]
    end

    test "returns empty list for missing keys" do
      theme_getter = Theme.from_theme(:missing)
      theme_config = %{spacing: ["1", "2", "4"]}

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == []
    end

    test "handles nil theme config" do
      theme_getter = Theme.from_theme(:spacing)

      result = Theme.call_theme_getter(theme_getter, %{})
      assert result == []
    end

    test "converts non-list values to lists" do
      theme_getter = Theme.from_theme(:single_value)
      theme_config = %{single_value: "only-value"}

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == ["only-value"]
    end

    test "works with regular functions for backwards compatibility" do
      regular_func = fn theme_config -> Map.get(theme_config, :test, []) end
      theme_config = %{test: ["value1", "value2"]}

      result = Theme.call_theme_getter(regular_func, theme_config)
      assert result == ["value1", "value2"]
    end

    test "handles complex theme configurations" do
      theme_getter = Theme.from_theme(:color)

      theme_config = %{
        color: [
          "transparent",
          "current",
          "black",
          "white",
          %{"gray" => ["50", "100", "200", "300"]},
          %{"red" => ["500", "600", "700"]}
        ]
      }

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert length(result) == 6
      assert "transparent" in result
      assert "current" in result
    end
  end

  describe "theme_getter?/1" do
    test "returns true for ThemeGetter structs" do
      theme_getter = Theme.from_theme(:spacing)
      assert Theme.theme_getter?(theme_getter) == true
    end

    test "returns false for regular functions" do
      regular_func = fn x -> x end
      assert Theme.theme_getter?(regular_func) == false
    end

    test "returns false for other data types" do
      assert Theme.theme_getter?("string") == false
      assert Theme.theme_getter?(123) == false
      assert Theme.theme_getter?(%{}) == false
      assert Theme.theme_getter?([]) == false
      assert Theme.theme_getter?(nil) == false
    end

    test "returns false for structs that are not ThemeGetter" do
      other_struct = %{__struct__: SomeOtherStruct, data: "test"}
      assert Theme.theme_getter?(other_struct) == false
    end
  end

  describe "convenience functions" do
    setup do
      theme_config = %{
        spacing: ["0", "1", "2", "4", "8", "16"],
        color: ["red", "blue", "green"],
        font: ["sans", "serif", "mono"],
        radius: ["none", "sm", "md", "lg"],
        shadow: ["sm", "md", "lg", "xl"],
        text: ["xs", "sm", "base", "lg"],
        "font-weight": ["thin", "normal", "bold"],
        tracking: ["tight", "normal", "wide"],
        leading: ["none", "tight", "normal"],
        breakpoint: ["sm", "md", "lg", "xl"],
        container: ["sm", "md", "lg", "xl"],
        blur: ["none", "sm", "md", "lg"],
        "drop-shadow": ["sm", "md", "lg"],
        "inset-shadow": ["sm", "md", "lg"],
        "text-shadow": ["sm", "md", "lg"],
        perspective: ["none", "sm", "md"],
        aspect: ["auto", "square", "video"],
        ease: ["linear", "in", "out"],
        animate: ["none", "spin", "pulse"]
      }

      {:ok, theme_config: theme_config}
    end

    test "spacing/1 returns spacing values", %{theme_config: theme_config} do
      result = Theme.spacing(theme_config)
      assert result == ["0", "1", "2", "4", "8", "16"]
    end

    test "color/1 returns color values", %{theme_config: theme_config} do
      result = Theme.color(theme_config)
      assert result == ["red", "blue", "green"]
    end

    test "font/1 returns font values", %{theme_config: theme_config} do
      result = Theme.font(theme_config)
      assert result == ["sans", "serif", "mono"]
    end

    test "radius/1 returns radius values", %{theme_config: theme_config} do
      result = Theme.radius(theme_config)
      assert result == ["none", "sm", "md", "lg"]
    end

    test "shadow/1 returns shadow values", %{theme_config: theme_config} do
      result = Theme.shadow(theme_config)
      assert result == ["sm", "md", "lg", "xl"]
    end

    test "text/1 returns text values", %{theme_config: theme_config} do
      result = Theme.text(theme_config)
      assert result == ["xs", "sm", "base", "lg"]
    end

    test "font_weight/1 returns font-weight values", %{theme_config: theme_config} do
      result = Theme.font_weight(theme_config)
      assert result == ["thin", "normal", "bold"]
    end

    test "tracking/1 returns tracking values", %{theme_config: theme_config} do
      result = Theme.tracking(theme_config)
      assert result == ["tight", "normal", "wide"]
    end

    test "leading/1 returns leading values", %{theme_config: theme_config} do
      result = Theme.leading(theme_config)
      assert result == ["none", "tight", "normal"]
    end

    test "breakpoint/1 returns breakpoint values", %{theme_config: theme_config} do
      result = Theme.breakpoint(theme_config)
      assert result == ["sm", "md", "lg", "xl"]
    end

    test "container/1 returns container values", %{theme_config: theme_config} do
      result = Theme.container(theme_config)
      assert result == ["sm", "md", "lg", "xl"]
    end

    test "blur/1 returns blur values", %{theme_config: theme_config} do
      result = Theme.blur(theme_config)
      assert result == ["none", "sm", "md", "lg"]
    end

    test "drop_shadow/1 returns drop-shadow values", %{theme_config: theme_config} do
      result = Theme.drop_shadow(theme_config)
      assert result == ["sm", "md", "lg"]
    end

    test "inset_shadow/1 returns inset-shadow values", %{theme_config: theme_config} do
      result = Theme.inset_shadow(theme_config)
      assert result == ["sm", "md", "lg"]
    end

    test "text_shadow/1 returns text-shadow values", %{theme_config: theme_config} do
      result = Theme.text_shadow(theme_config)
      assert result == ["sm", "md", "lg"]
    end

    test "perspective/1 returns perspective values", %{theme_config: theme_config} do
      result = Theme.perspective(theme_config)
      assert result == ["none", "sm", "md"]
    end

    test "aspect/1 returns aspect values", %{theme_config: theme_config} do
      result = Theme.aspect(theme_config)
      assert result == ["auto", "square", "video"]
    end

    test "ease/1 returns ease values", %{theme_config: theme_config} do
      result = Theme.ease(theme_config)
      assert result == ["linear", "in", "out"]
    end

    test "animate/1 returns animate values", %{theme_config: theme_config} do
      result = Theme.animate(theme_config)
      assert result == ["none", "spin", "pulse"]
    end

    test "convenience functions handle missing keys gracefully" do
      empty_config = %{}

      assert Theme.spacing(empty_config) == []
      assert Theme.color(empty_config) == []
      assert Theme.font(empty_config) == []
      assert Theme.radius(empty_config) == []
      assert Theme.shadow(empty_config) == []
    end
  end

  describe "integration with configuration" do
    test "theme getters work in class group definitions" do
      # This test ensures that the theme getters can be used in the actual
      # configuration and that the theme_getter?/1 function correctly identifies them

      theme_spacing = Theme.from_theme(:spacing)
      theme_color = Theme.from_theme(:color)

      # These should be identified as theme getters
      assert Theme.theme_getter?(theme_spacing) == true
      assert Theme.theme_getter?(theme_color) == true

      # Test that they can be called
      theme_config = %{
        spacing: ["1", "2", "4"],
        color: ["red", "blue"]
      }

      spacing_result = Theme.call_theme_getter(theme_spacing, theme_config)
      color_result = Theme.call_theme_getter(theme_color, theme_config)

      assert spacing_result == ["1", "2", "4"]
      assert color_result == ["red", "blue"]
    end

    test "theme getters can be mixed with other class definitions" do
      # This simulates how theme getters would be used in a real class group
      theme_spacing = Theme.from_theme(:spacing)

      class_definitions = [
        "auto",
        "full",
        theme_spacing
      ]

      # Verify the structure
      assert length(class_definitions) == 3
      assert "auto" in class_definitions
      assert "full" in class_definitions
      assert Theme.theme_getter?(Enum.at(class_definitions, 2)) == true
    end
  end

  describe "error handling" do
    test "handles invalid theme configurations gracefully" do
      theme_getter = Theme.from_theme(:spacing)

      # Test with various invalid configurations
      assert Theme.call_theme_getter(theme_getter, nil) == []
      assert Theme.call_theme_getter(theme_getter, "not a map") == []
      assert Theme.call_theme_getter(theme_getter, 123) == []
    end

    test "theme_getter?/1 handles invalid inputs gracefully" do
      # Should not raise errors for any input
      assert Theme.theme_getter?(nil) == false
      assert Theme.theme_getter?("string") == false
      assert Theme.theme_getter?(123) == false
      assert Theme.theme_getter?([1, 2, 3]) == false
      assert Theme.theme_getter?(%{random: "map"}) == false
    end
  end

  describe "TypeScript compatibility" do
    test "mimics TypeScript fromTheme behavior" do
      # Test that our implementation behaves like the TypeScript version
      theme_getter = Theme.from_theme("spacing")

      # Should be identified as a theme getter (equivalent to isThemeGetter: true)
      assert Theme.theme_getter?(theme_getter) == true

      # Should extract values from theme config
      theme_config = %{spacing: ["hello"]}
      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == ["hello"]

      # Should return empty array for missing keys
      empty_result = Theme.call_theme_getter(theme_getter, %{})
      assert empty_result == []
    end

    test "supports generic type equivalents" do
      # In TypeScript: fromTheme<string>('foo')
      # In Elixir: Theme.from_theme(:foo)
      custom_theme_getter = Theme.from_theme(:foo)

      assert Theme.theme_getter?(custom_theme_getter) == true

      theme_config = %{foo: ["hello"]}
      result = Theme.call_theme_getter(custom_theme_getter, theme_config)
      assert result == ["hello"]
    end
  end
end
