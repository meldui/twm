defmodule Twm.ClassMapTest do
  use ExUnit.Case, async: true

  alias Twm.{Config, ClassGroupUtils}

  describe "class map structure" do
    test "class map has correct class groups at first part" do
      class_map = ClassGroupUtils.create_class_map(Config.get_default())

      class_groups_by_first_part =
        class_map.next_part
        |> Enum.map(fn {key, value} ->
          {key, get_class_groups_in_class_part(value) |> Enum.sort()}
        end)
        |> Enum.into(%{})

      refute class_map.class_group_id
      assert length(class_map.validators) == 0

      # Test core entries that should work correctly
      assert Map.get(class_groups_by_first_part, "block") == ["display"]
      assert Map.get(class_groups_by_first_part, "inline") == ["display"]
      assert Map.get(class_groups_by_first_part, "hidden") == ["display"]
      assert Map.get(class_groups_by_first_part, "absolute") == ["position"]
      assert Map.get(class_groups_by_first_part, "relative") == ["position"]
      assert Map.get(class_groups_by_first_part, "static") == ["position"]

      # Test flex structure - this is critical for proper functionality
      flex_groups = Map.get(class_groups_by_first_part, "flex")
      assert "display" in flex_groups, "flex should include display group"
      assert "flex" in flex_groups, "flex should include flex group"
      assert "flex-direction" in flex_groups, "flex should include flex-direction group"
      assert "flex-wrap" in flex_groups, "flex should include flex-wrap group"

      # Test grid structure
      grid_groups = Map.get(class_groups_by_first_part, "grid")
      assert "display" in grid_groups, "grid should include display group"

      # Test spacing utilities
      assert Map.get(class_groups_by_first_part, "p") == ["p"]
      assert Map.get(class_groups_by_first_part, "m") == ["m"]
      assert Map.get(class_groups_by_first_part, "px") == ["px"]
      assert Map.get(class_groups_by_first_part, "py") == ["py"]

      # Test visibility
      visibility_groups = Map.get(class_groups_by_first_part, "visible")
      assert visibility_groups == ["visibility"]
      
      invisible_groups = Map.get(class_groups_by_first_part, "invisible")
      assert invisible_groups == ["visibility"]

      # Test that essential entries exist
      essential_keys = [
        "block", "inline", "flex", "grid", "hidden",
        "absolute", "relative", "static", "fixed",
        "p", "m", "px", "py", "mx", "my",
        "w", "h"
      ]

      Enum.each(essential_keys, fn key ->
        groups = Map.get(class_groups_by_first_part, key)
        assert groups != nil && groups != [], "Expected groups for #{key}, got: #{inspect(groups)}"
      end)

      # Verify the class map structure is working correctly
      # Check that we have a reasonable number of first-part entries
      assert map_size(class_groups_by_first_part) > 50, "Expected many class map entries, got: #{map_size(class_groups_by_first_part)}"
    end
  end

  # Helper function to recursively collect all class group IDs from a class part object
  defp get_class_groups_in_class_part(class_part) do
    %{class_group_id: class_group_id, validators: validators, next_part: next_part} = class_part

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
      Enum.reduce(validators, class_groups, fn %{class_group_id: validator_class_group_id}, acc ->
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