defmodule Twm.Config.ThemeIntegrationTest do
  use ExUnit.Case, async: true

  alias Twm.Config.Theme
  alias Twm.ClassGroupUtils

  describe "theme getters in configuration" do
    test "theme getters are properly identified by the class group utils" do
      theme_spacing = Theme.from_theme(:spacing)
      theme_color = Theme.from_theme(:color)
      regular_function = fn _config -> ["test"] end

      # Test that theme getters are properly identified
      assert Theme.theme_getter?(theme_spacing) == true
      assert Theme.theme_getter?(theme_color) == true
      assert Theme.theme_getter?(regular_function) == false
    end

    test "theme getters work in class group processing" do
      theme_spacing = Theme.from_theme(:spacing)

      # Create a simple configuration with theme getters
      config =
        Twm.Config.new(
          theme: [
            spacing: ["1", "2", "4", "8", "16"]
          ],
          class_groups: [
            margin: ["auto", theme_spacing]
          ],
          conflicting_class_groups: [],
          conflicting_class_group_modifiers: []
        )

      # Create class group utils
      context = ClassGroupUtils.create_class_group_utils(config)

      # Test that the context is created successfully
      assert %Twm.Context.ClassGroupProcessingContext{} = context

      # Test that classes from the theme are recognized
      # Note: This would depend on the full implementation of class group processing
      # For now, we're just testing that the context is created without errors
      assert is_list(context.class_map)
    end

    test "theme getters can be mixed with other class definitions" do
      theme_spacing = Theme.from_theme(:spacing)
      regular_validator = fn class_part -> String.match?(class_part, ~r/^\d+$/) end

      class_definitions = [
        "auto",
        "full",
        theme_spacing,
        regular_validator
      ]

      # Verify the structure contains different types of definitions
      assert length(class_definitions) == 4
      assert "auto" in class_definitions
      assert "full" in class_definitions

      # Find and verify the theme getter
      theme_getter = Enum.find(class_definitions, &Theme.theme_getter?/1)
      assert theme_getter != nil
      assert Theme.theme_getter?(theme_getter) == true

      # Find and verify the regular validator
      validator =
        Enum.find(class_definitions, fn item ->
          is_function(item) and not Theme.theme_getter?(item)
        end)

      assert validator != nil
      assert is_function(validator)
    end

    test "theme getters work with real theme configuration" do
      # Create theme getters for common properties
      theme_spacing = Theme.from_theme(:spacing)
      theme_color = Theme.from_theme(:color)
      theme_radius = Theme.from_theme(:radius)

      # Create a realistic theme configuration
      theme_config = [
        spacing: [
          "0",
          "px",
          "0.5",
          "1",
          "1.5",
          "2",
          "2.5",
          "3",
          "3.5",
          "4",
          "5",
          "6",
          "7",
          "8",
          "9",
          "10",
          "11",
          "12",
          "14",
          "16",
          "20",
          "24",
          "28",
          "32",
          "36",
          "40",
          "44",
          "48",
          "52",
          "56",
          "60",
          "64",
          "72",
          "80",
          "96"
        ],
        color: [
          "inherit",
          "current",
          "transparent",
          "black",
          "white",
          "slate-50",
          "slate-100",
          "slate-200",
          "slate-300",
          "slate-400",
          "slate-500",
          "gray-50",
          "gray-100",
          "gray-200",
          "gray-300",
          "gray-400",
          "gray-500",
          "red-50",
          "red-100",
          "red-200",
          "red-300",
          "red-400",
          "red-500",
          "blue-50",
          "blue-100",
          "blue-200",
          "blue-300",
          "blue-400",
          "blue-500"
        ],
        radius: [
          "none",
          "sm",
          "md",
          "lg",
          "xl",
          "2xl",
          "3xl",
          "full"
        ]
      ]

      # Test that theme getters extract the correct values
      spacing_values = Theme.call_theme_getter(theme_spacing, theme_config)
      color_values = Theme.call_theme_getter(theme_color, theme_config)
      radius_values = Theme.call_theme_getter(theme_radius, theme_config)

      assert length(spacing_values) == 35
      assert "0" in spacing_values
      assert "px" in spacing_values
      assert "96" in spacing_values

      assert length(color_values) == 29
      assert "inherit" in color_values
      assert "transparent" in color_values
      assert "blue-500" in color_values

      assert length(radius_values) == 8
      assert "none" in radius_values
      assert "full" in radius_values
    end

    test "theme getters handle missing theme keys gracefully" do
      theme_missing = Theme.from_theme(:nonexistent)

      theme_config = [
        spacing: ["1", "2", "4"],
        color: ["red", "blue"]
      ]

      # Should return empty list for missing keys
      result = Theme.call_theme_getter(theme_missing, theme_config)
      assert result == []
    end

    test "theme getters work with hyphenated keys" do
      theme_font_weight = Theme.from_theme(:"font-weight")
      theme_drop_shadow = Theme.from_theme(:"drop-shadow")

      theme_config = [
        "font-weight": ["thin", "normal", "bold", "black"],
        "drop-shadow": ["sm", "md", "lg", "xl"]
      ]

      font_weight_values = Theme.call_theme_getter(theme_font_weight, theme_config)
      drop_shadow_values = Theme.call_theme_getter(theme_drop_shadow, theme_config)

      assert font_weight_values == ["thin", "normal", "bold", "black"]
      assert drop_shadow_values == ["sm", "md", "lg", "xl"]
    end

    test "theme getters maintain performance with large theme configurations" do
      theme_spacing = Theme.from_theme(:spacing)

      # Create a large theme configuration
      large_spacing_values = Enum.map(0..1000, &to_string/1)
      theme_config = [spacing: large_spacing_values]

      # Measure time (this is more for ensuring no obvious performance issues)
      {time, result} =
        :timer.tc(fn ->
          Theme.call_theme_getter(theme_spacing, theme_config)
        end)

      # Should complete quickly (less than 1ms for this simple operation)
      # microseconds
      assert time < 1000
      assert length(result) == 1001
      assert "0" in result
      assert "1000" in result
    end

    test "theme getters work with nested theme structures" do
      theme_color = Theme.from_theme(:color)

      # Create a theme configuration with nested color definitions
      theme_config = [
        color: [
          "transparent",
          "current",
          %{
            "gray" => ["50", "100", "200", "300", "400", "500"],
            "red" => ["50", "100", "200", "300", "400", "500"],
            "blue" => ["50", "100", "200", "300", "400", "500"]
          }
        ]
      ]

      color_values = Theme.call_theme_getter(theme_color, theme_config)

      # Should include both direct values and nested structures
      assert length(color_values) == 3
      assert "transparent" in color_values
      assert "current" in color_values

      # The nested map should be preserved as-is for further processing
      nested_colors = Enum.find(color_values, &is_map/1)
      assert nested_colors != nil
      assert nested_colors["gray"] == ["50", "100", "200", "300", "400", "500"]
    end
  end

  describe "backwards compatibility" do
    test "convenience functions still work as before" do
      theme_config = [
        spacing: ["1", "2", "4"],
        color: ["red", "blue"],
        font: ["sans", "serif"]
      ]

      # Test that the old convenience functions still work
      assert Theme.spacing(theme_config) == ["1", "2", "4"]
      assert Theme.color(theme_config) == ["red", "blue"]
      assert Theme.font(theme_config) == ["sans", "serif"]
    end

    test "regular functions are still supported by call_theme_getter" do
      regular_func = fn theme_config ->
        Keyword.get(theme_config, :custom, [])
      end

      theme_config = [custom: ["value1", "value2"]]

      result = Theme.call_theme_getter(regular_func, theme_config)
      assert result == ["value1", "value2"]
    end
  end
end
