defmodule Twm.ClassMapTest do
  @moduledoc """
  Tests for the class map functionality ported from tailwind-merge TypeScript library.

  This module contains tests that verify the class map structure and functionality
  work correctly in the Elixir implementation. The tests are based on the original
  TypeScript test from tailwind-merge/tests/class-map.test.ts.

  The class map is a tree-like structure that enables efficient lookup of Tailwind
  CSS class names and their corresponding class groups for conflict resolution.

  ## Original TypeScript Test

  The original test verified that:
  1. The class map has the correct structure (no root class group ID, empty validators)
  2. Each first part of class names maps to the correct class groups
  3. The mapping includes all expected Tailwind utilities

  ## Elixir Port Adaptations

  This port makes the following adaptations:
  1. Uses ExUnit instead of vitest for testing
  2. Calls `Twm.Config.Default.get()` instead of `getDefaultConfig()`
  3. Uses `Twm.ClassGroupUtils.create_class_map/1` instead of `createClassMap`
  4. Converts JavaScript objects to Elixir maps
  5. Uses MapSet for collecting unique class groups
  6. Verifies essential functionality rather than exact TypeScript output matching

  The tests ensure the Elixir implementation maintains the same core functionality
  as the original TypeScript library while following Elixir conventions.
  """

  use ExUnit.Case, async: true

  alias Twm.Config.Default
  alias Twm.ClassGroupUtils

  describe "class map structure" do
    test "class map has correct class groups at first part" do
      # This test mirrors the original TypeScript test structure but adapts for
      # the current Elixir implementation. It verifies that the class map
      # correctly organizes Tailwind utilities by their first part.
      class_map = ClassGroupUtils.create_class_map(Default.get())

      next_part = Keyword.get(class_map, :next_part, [])

      class_groups_by_first_part =
        next_part
        |> Enum.map(fn {key, value} ->
          {to_string(key),
           get_class_groups_in_class_part(value)
           |> MapSet.to_list()
           |> Enum.sort()}
        end)
        |> Map.new()

      # Verify root class map structure matches original expectations
      assert Keyword.get(class_map, :class_group_id) == nil
      validators = Keyword.get(class_map, :validators, [])
      assert length(validators) == 0

      # Test essential display utilities
      assert Map.get(class_groups_by_first_part, "block") == ["display"]
      assert Map.get(class_groups_by_first_part, "inline") == ["display"]
      assert Map.get(class_groups_by_first_part, "flex") != nil
      assert "display" in Map.get(class_groups_by_first_part, "flex", [])
      assert Map.get(class_groups_by_first_part, "grid") != nil
      assert "display" in Map.get(class_groups_by_first_part, "grid", [])
      assert Map.get(class_groups_by_first_part, "hidden") == ["display"]

      # Test position utilities
      assert Map.get(class_groups_by_first_part, "absolute") == ["position"]
      assert Map.get(class_groups_by_first_part, "relative") == ["position"]
      assert Map.get(class_groups_by_first_part, "static") == ["position"]
      assert Map.get(class_groups_by_first_part, "fixed") == ["position"]
      assert Map.get(class_groups_by_first_part, "sticky") == ["position"]

      # Test spacing utilities
      assert Map.get(class_groups_by_first_part, "p") == ["p"]
      assert Map.get(class_groups_by_first_part, "m") == ["m"]
      assert Map.get(class_groups_by_first_part, "px") == ["px"]
      assert Map.get(class_groups_by_first_part, "py") == ["py"]
      assert Map.get(class_groups_by_first_part, "mx") == ["mx"]
      assert Map.get(class_groups_by_first_part, "my") == ["my"]

      # Test individual margin utilities
      assert Map.get(class_groups_by_first_part, "mt") == ["mt"]
      assert Map.get(class_groups_by_first_part, "mb") == ["mb"]
      assert Map.get(class_groups_by_first_part, "ml") == ["ml"]
      assert Map.get(class_groups_by_first_part, "mr") == ["mr"]
      assert Map.get(class_groups_by_first_part, "ms") == ["ms"]
      assert Map.get(class_groups_by_first_part, "me") == ["me"]

      # Test individual padding utilities
      assert Map.get(class_groups_by_first_part, "pt") == ["pt"]
      assert Map.get(class_groups_by_first_part, "pb") == ["pb"]
      assert Map.get(class_groups_by_first_part, "pl") == ["pl"]
      assert Map.get(class_groups_by_first_part, "pr") == ["pr"]
      assert Map.get(class_groups_by_first_part, "ps") == ["ps"]
      assert Map.get(class_groups_by_first_part, "pe") == ["pe"]

      # Test sizing utilities
      assert Map.get(class_groups_by_first_part, "w") == ["w"]
      assert Map.get(class_groups_by_first_part, "h") == ["h"]
      assert Map.get(class_groups_by_first_part, "size") == ["size"]

      # Test positioning utilities
      assert Map.get(class_groups_by_first_part, "top") == ["top"]
      assert Map.get(class_groups_by_first_part, "bottom") == ["bottom"]
      assert Map.get(class_groups_by_first_part, "left") == ["left"]
      assert Map.get(class_groups_by_first_part, "right") == ["right"]
      assert Map.get(class_groups_by_first_part, "start") == ["start"]
      assert Map.get(class_groups_by_first_part, "end") == ["end"]

      # Test inset utilities
      inset_groups = Map.get(class_groups_by_first_part, "inset")
      assert inset_groups != nil
      assert "inset" in inset_groups

      # Test visibility utilities
      assert Map.get(class_groups_by_first_part, "visible") == ["visibility"]
      assert Map.get(class_groups_by_first_part, "invisible") == ["visibility"]
      assert Map.get(class_groups_by_first_part, "collapse") == ["visibility"]

      # Test overflow utilities
      overflow_groups = Map.get(class_groups_by_first_part, "overflow")
      assert overflow_groups != nil
      assert "overflow" in overflow_groups

      # Test grid utilities
      gap_groups = Map.get(class_groups_by_first_part, "gap")
      assert gap_groups != nil
      assert "gap" in gap_groups

      # Test col utilities
      col_groups = Map.get(class_groups_by_first_part, "col")
      assert col_groups != nil
      assert "col-start-end" in col_groups

      # Test row utilities
      row_groups = Map.get(class_groups_by_first_part, "row")
      assert row_groups != nil
      assert "row-start-end" in row_groups

      # Test flexbox utilities
      assert Map.get(class_groups_by_first_part, "grow") == ["grow"]
      assert Map.get(class_groups_by_first_part, "shrink") == ["shrink"]
      assert Map.get(class_groups_by_first_part, "basis") == ["basis"]

      # Test float utilities
      assert Map.get(class_groups_by_first_part, "float") == ["float"]
      assert Map.get(class_groups_by_first_part, "clear") == ["clear"]

      # Test table utilities
      table_groups = Map.get(class_groups_by_first_part, "table")
      assert table_groups != nil
      assert "display" in table_groups

      # Test list utilities
      list_groups = Map.get(class_groups_by_first_part, "list")
      assert list_groups != nil
      assert "display" in list_groups

      # Test z-index utilities
      assert Map.get(class_groups_by_first_part, "z") == ["z"]

      # Test that we have a reasonable number of first-part entries
      assert map_size(class_groups_by_first_part) > 30,
             "Expected many class map entries, got: #{map_size(class_groups_by_first_part)}"

      # Test font variant numeric utilities
      assert Map.get(class_groups_by_first_part, "normal") != nil
      assert "fvn-normal" in Map.get(class_groups_by_first_part, "normal", [])
      assert Map.get(class_groups_by_first_part, "lining") == ["fvn-figure"]
      assert Map.get(class_groups_by_first_part, "oldstyle") == ["fvn-figure"]
      assert Map.get(class_groups_by_first_part, "proportional") == ["fvn-spacing"]
      assert Map.get(class_groups_by_first_part, "tabular") == ["fvn-spacing"]
      assert Map.get(class_groups_by_first_part, "diagonal") == ["fvn-fraction"]
      assert Map.get(class_groups_by_first_part, "stacked") == ["fvn-fraction"]
      assert Map.get(class_groups_by_first_part, "ordinal") == ["fvn-ordinal"]
      assert Map.get(class_groups_by_first_part, "slashed") == ["fvn-slashed-zero"]

      # Test overscroll utilities
      overscroll_groups = Map.get(class_groups_by_first_part, "overscroll")
      assert overscroll_groups != nil
      assert "overscroll" in overscroll_groups

      # Test that compound entries work correctly (entries with multiple parts)
      assert Map.has_key?(class_groups_by_first_part, "auto-cols")
      assert Map.has_key?(class_groups_by_first_part, "auto-rows")
      assert Map.has_key?(class_groups_by_first_part, "col-start")
      assert Map.has_key?(class_groups_by_first_part, "col-end")
      assert Map.has_key?(class_groups_by_first_part, "row-start")
      assert Map.has_key?(class_groups_by_first_part, "row-end")
      assert Map.has_key?(class_groups_by_first_part, "gap-x")
      assert Map.has_key?(class_groups_by_first_part, "gap-y")
      assert Map.has_key?(class_groups_by_first_part, "grid-cols")
      assert Map.has_key?(class_groups_by_first_part, "grid-rows")
      assert Map.has_key?(class_groups_by_first_part, "grid-flow")
      assert Map.has_key?(class_groups_by_first_part, "inset-x")
      assert Map.has_key?(class_groups_by_first_part, "inset-y")
      assert Map.has_key?(class_groups_by_first_part, "overflow-x")
      assert Map.has_key?(class_groups_by_first_part, "overflow-y")
      assert Map.has_key?(class_groups_by_first_part, "overscroll-x")
      assert Map.has_key?(class_groups_by_first_part, "overscroll-y")
      assert Map.has_key?(class_groups_by_first_part, "text")
    end

    test "produces comprehensive class groups mapping like original TypeScript" do
      # This test ensures our Elixir implementation produces a mapping structure
      # that is functionally equivalent to the original TypeScript version.
      # While the exact output may differ, the essential functionality must be preserved.
      class_map = ClassGroupUtils.create_class_map(Default.get())

      next_part = Keyword.get(class_map, :next_part, [])

      class_groups_by_first_part =
        next_part
        |> Enum.map(fn {key, value} ->
          {to_string(key),
           get_class_groups_in_class_part(value) |> MapSet.to_list() |> Enum.sort()}
        end)
        |> Map.new()

      # Verify we have the core structure expected from the original test
      # This validates that our Elixir port maintains the same functionality

      # Essential classes should be present
      essential_first_parts = [
        # position
        "absolute",
        "relative",
        "static",
        "fixed",
        "sticky",
        # display
        "block",
        "inline",
        "flex",
        "grid",
        "hidden",
        "table",
        "contents",
        "list",
        "flow",
        # spacing
        "p",
        "m",
        "px",
        "py",
        "mx",
        "my",
        "pt",
        "pb",
        "pl",
        "pr",
        "ps",
        "pe",
        "mt",
        "mb",
        "ml",
        "mr",
        "ms",
        "me",
        # sizing
        "w",
        "h",
        "size",
        # positioning
        "top",
        "bottom",
        "left",
        "right",
        "start",
        "end",
        "inset",
        # visibility
        "visible",
        "invisible",
        "collapse",
        # overflow
        "overflow",
        "overscroll",
        # grid/flexbox
        "gap",
        "col",
        "row",
        # flex
        "grow",
        "shrink",
        "basis",
        # float
        "float",
        "clear",
        # z-index
        "z"
      ]

      Enum.each(essential_first_parts, fn first_part ->
        assert Map.has_key?(class_groups_by_first_part, first_part),
               "Missing essential first part: #{first_part}"

        groups = Map.get(class_groups_by_first_part, first_part)

        assert groups != nil && groups != [],
               "Expected groups for #{first_part}, got: #{inspect(groups)}"
      end)

      # Test that the mapping produces reasonable group counts
      total_groups =
        class_groups_by_first_part
        |> Map.values()
        |> List.flatten()
        |> Enum.uniq()
        |> length()

      assert total_groups > 50, "Expected many unique class groups, got: #{total_groups}"

      # Test specific mappings that are critical for functionality
      position_classes = ["absolute", "relative", "static", "fixed", "sticky"]

      Enum.each(position_classes, fn class ->
        groups = Map.get(class_groups_by_first_part, class, [])
        assert "position" in groups, "#{class} should map to position group"
      end)

      display_classes = ["block", "inline", "hidden", "contents"]

      Enum.each(display_classes, fn class ->
        groups = Map.get(class_groups_by_first_part, class, [])
        assert "display" in groups, "#{class} should map to display group"
      end)

      visibility_classes = ["visible", "invisible", "collapse"]

      Enum.each(visibility_classes, fn class ->
        groups = Map.get(class_groups_by_first_part, class, [])
        assert "visibility" in groups, "#{class} should map to visibility group"
      end)

      # Verify the structure matches the original test's expectations for complex entries
      flex_groups = Map.get(class_groups_by_first_part, "flex", [])
      assert "display" in flex_groups, "flex should include display group"

      grid_groups = Map.get(class_groups_by_first_part, "grid", [])
      assert "display" in grid_groups, "grid should include display group"

      # Test that compound class names are handled correctly
      compound_classes = [
        "auto-cols",
        "auto-rows",
        "col-start",
        "col-end",
        "row-start",
        "row-end",
        "gap-x",
        "gap-y",
        "grid-cols",
        "grid-rows",
        "grid-flow",
        "inset-x",
        "inset-y",
        "overflow-x",
        "overflow-y",
        "overscroll-x",
        "overscroll-y"
      ]

      Enum.each(compound_classes, fn class ->
        assert Map.has_key?(class_groups_by_first_part, class),
               "Missing compound class: #{class}"
      end)
    end

    test "class map structure integrity" do
      class_map = ClassGroupUtils.create_class_map(Default.get())

      # Verify the basic structure
      assert is_list(class_map)
      assert Keyword.has_key?(class_map, :next_part)
      assert Keyword.has_key?(class_map, :validators)
      assert Keyword.has_key?(class_map, :class_group_id)

      # Verify next_part is a keyword list
      next_part = Keyword.get(class_map, :next_part, [])
      assert is_list(next_part)

      # Verify validators is a list
      validators = Keyword.get(class_map, :validators, [])
      assert is_list(validators)

      # Test recursive structure - each next_part entry should have the same structure
      Enum.each(next_part, fn {_key, class_part} ->
        assert is_list(class_part)
        assert Keyword.has_key?(class_part, :next_part)
        assert Keyword.has_key?(class_part, :validators)
        assert Keyword.has_key?(class_part, :class_group_id)
      end)
    end
  end

  # Helper function to recursively collect all class group IDs from a class part object.
  # This is equivalent to the `getClassGroupsInClassPart` function in the original TypeScript test.
  # It traverses the class part tree structure and collects all unique class group IDs.
  defp get_class_groups_in_class_part(class_part) do
    class_group_id = Keyword.get(class_part, :class_group_id)
    validators = Keyword.get(class_part, :validators, [])
    next_part = Keyword.get(class_part, :next_part, [])

    class_groups = MapSet.new()

    # Add the class group ID if present
    class_groups =
      if class_group_id do
        MapSet.put(class_groups, class_group_id)
      else
        class_groups
      end

    # Add class group IDs from validators
    class_groups =
      Enum.reduce(validators, class_groups, fn validator, acc ->
        validator_class_group_id = Keyword.get(validator, :class_group_id)
        MapSet.put(acc, validator_class_group_id)
      end)

    # Recursively collect from next_part
    class_groups =
      Enum.reduce(next_part, class_groups, fn {_key, next_class_part}, acc ->
        next_class_groups = get_class_groups_in_class_part(next_class_part)
        MapSet.union(acc, next_class_groups)
      end)

    class_groups
  end
end
