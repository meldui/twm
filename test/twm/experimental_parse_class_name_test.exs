defmodule Twm.ExperimentalParseClassNameTest do
  @moduledoc """
  Tests for the experimental parse class name functionality.

  These tests are ported from the TypeScript tailwind-merge library's
  experimental-parse-class-name.test.ts file.
  """

  use ExUnit.Case

  describe "experimental_parse_class_name" do
    test "default case" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              parse_class_name.(class_name)
            end
          ]
        )

      assert Twm.merge("px-2 py-1 p-3", config) == "p-3"
    end

    test "removing first three characters from class" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              stripped_class_name = String.slice(class_name, 3..-1//1)
              parse_class_name.(stripped_class_name)
            end
          ]
        )

      assert Twm.merge("barpx-2 foopy-1 lolp-3", config) == "p-3"
    end

    test "ignoring breakpoint modifiers" do
      breakpoints = MapSet.new(~w[sm md lg xl 2xl])

      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              parsed = parse_class_name.(class_name)

              filtered_modifiers =
                parsed.modifiers
                |> Enum.filter(&(!MapSet.member?(breakpoints, &1)))

              %{parsed | modifiers: filtered_modifiers}
            end
          ]
        )

      assert Twm.merge("md:px-2 hover:py-4 py-1 lg:p-3", config) == "hover:py-4 p-3"
    end

    test "custom parsing with complex modifiers" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              # Transform class names by prefixing with "custom-" if they don't already have it
              transformed_class_name =
                if String.starts_with?(class_name, "custom-") do
                  class_name
                else
                  case String.split(class_name, ":", parts: 2) do
                    [modifier, base_class] -> "#{modifier}:custom-#{base_class}"
                    [base_class] -> "custom-#{base_class}"
                  end
                end

              parse_class_name.(transformed_class_name)
            end
          ]
        )

      # Test basic transformation with conflicting padding classes
      assert Twm.merge("px-2 px-4", config) == "custom-px-4"

      # Test with modifiers - hover:px-2 and focus:px-4 don't conflict, so both are kept
      assert Twm.merge("hover:px-2 focus:px-4", config) == "hover:custom-px-2 focus:custom-px-4"
    end

    test "experimental parser with important modifier" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              # Add "!" prefix to all classes for testing important modifier handling
              prefixed_class_name = "!" <> class_name
              parse_class_name.(prefixed_class_name)
            end
          ]
        )

      # px and py don't conflict directly, so both should be kept
      assert Twm.merge("px-2 py-1", config) == "!px-2 !py-1"
    end

    test "experimental parser returning unchanged parsed result" do
      # Test that returning the parsed result unchanged works correctly
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: _class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              # Parse with original function and return unchanged
              parsed = parse_class_name.("text-lg")
              parsed
            end
          ]
        )

      # All input classes should be ignored and replaced with "text-lg"
      assert Twm.merge("px-2 py-1 text-sm", config) == "text-lg"
    end

    test "experimental parser with arbitrary values" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              # Handle arbitrary values by wrapping them in extra brackets for testing
              transformed_class_name =
                if String.contains?(class_name, "[") && String.contains?(class_name, "]") do
                  String.replace(class_name, ~r/\[([^\]]+)\]/, "[[\\1]]")
                else
                  class_name
                end

              parse_class_name.(transformed_class_name)
            end
          ]
        )

      # Test with arbitrary values - the transformation should be applied
      assert Twm.merge("text-[12px] text-[14px]", config) == "text-[[14px]]"
    end

    test "experimental parser with multiple modifiers" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              parsed = parse_class_name.(class_name)

              # Remove all "dark" modifiers for testing
              filtered_modifiers =
                parsed.modifiers
                |> Enum.filter(&(&1 != "dark"))

              %{parsed | modifiers: filtered_modifiers}
            end
          ]
        )

      assert Twm.merge("dark:hover:px-2 hover:px-4 dark:px-6", config) == "hover:px-4 px-6"
    end

    test "experimental parser with external classes" do
      config =
        Twm.Config.extend(
          override: [
            experimental_parse_class_name: fn %{
                                                class_name: class_name,
                                                parse_class_name: parse_class_name
                                              } ->
              parsed = parse_class_name.(class_name)

              # Mark all classes starting with "ext-" as external
              if String.starts_with?(parsed.base_class_name, "ext-") do
                %{parsed | is_external: true}
              else
                parsed
              end
            end
          ]
        )

      # External classes should be preserved without conflict resolution

      assert Twm.merge("px-2 ext-px-4 px-6", config) == "ext-px-4 px-6"
    end
  end
end
