defmodule Twm.Merger do
  @moduledoc """
  Handles the core class merging logic for Twm.

  This module provides functions to merge Tailwind CSS classes, handling conflicts
  based on the provided configuration.
  """

  alias Twm.ClassGroupUtils

  @doc """
  Merges Tailwind CSS classes based on the provided configuration.

  This function takes a string of space-separated class names and merges them
  according to the Tailwind CSS conflict resolution rules defined in the configuration.

  ## Examples

      iex> config = Twm.Config.get_default()
      iex> Twm.Merger.merge_classes("px-2 px-4", config)
      "px-4"

      iex> config = Twm.Config.get_default()
      iex> Twm.Merger.merge_classes("pt-2 pt-4 pb-3", config)
      "pt-4 pb-3"

  """
  @spec merge_classes(String.t(), map()) :: String.t()
  def merge_classes(classes, config) when is_binary(classes) and is_map(config) do
    if classes == "" do
      ""
    else
      class_list = String.split(classes, ~r/\s+/, trim: true)
      
      # Create class group utilities for the config
      class_utils = ClassGroupUtils.create_class_group_utils(config)
      
      # Parse classes and merge conflicts
      merge_class_list(class_list, class_utils)
    end
  end

  # Merge a list of classes using the class utilities
  defp merge_class_list(class_list, class_utils) do
    # Parse each class and track conflicts
    parsed_classes = Enum.map(class_list, &parse_class_with_modifiers(&1, class_utils))
    
    # Group by conflict keys and handle conflicting class groups
    result_map = 
      parsed_classes
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{class, parsed_info}, index}, acc ->
        class_group_id = parsed_info.class_group_id
        modifiers = parsed_info.modifiers
        important = parsed_info.important
        
        # Create the primary conflict key for this class
        conflict_key = get_conflict_key(parsed_info, class_utils)
        
        # Get all conflicting class group IDs
        conflicting_groups = if class_group_id do
          class_utils.get_conflicting_class_group_ids.(class_group_id, false)
        else
          []
        end
        
        # Remove any existing classes that conflict with this one
        updated_acc = remove_conflicting_classes(acc, class_group_id, conflicting_groups, modifiers, important)
        
        # Add this class to the map
        Map.put(updated_acc, conflict_key, {class, index, parsed_info})
      end)
    
    # Sort by original index to maintain order and extract classes
    result_map
    |> Map.values()
    |> Enum.sort_by(fn {_class, index, _parsed} -> index end)
    |> Enum.map(fn {class, _index, _parsed} -> class end)
    |> Enum.join(" ")
  end

  # Parse a class with its modifiers and important flag
  defp parse_class_with_modifiers(class, class_utils) do
    {important, base_class} = extract_important(class)
    {modifiers, class_name} = extract_modifiers(base_class)
    
    class_group_id = class_utils.get_class_group_id.(class_name)
    
    parsed_info = %{
      class_group_id: class_group_id,
      modifiers: modifiers,
      important: important,
      base_class: class_name
    }
    
    {class, parsed_info}
  end

  # Extract important flag from class
  defp extract_important("!" <> class), do: {true, class}
  defp extract_important(class), do: {false, class}

  # Extract modifiers from class using regex to handle arbitrary properties correctly
  # Examples: 
  # - "hover:[paint-order:normal]" -> {["hover"], "[paint-order:normal]"}
  # - "[paint-order:markers]" -> {[], "[paint-order:markers]"}
  # - "hover:focus:px-4" -> {["hover", "focus"], "px-4"}
  defp extract_modifiers(class) do
    # Use regex to match modifiers followed by the actual class
    # This pattern looks for zero or more "modifier:" parts followed by the class
    case Regex.run(~r/^((?:[^:\[\]]+:)*)(.+)$/, class) do
      [_full, modifiers_part, class_part] ->
        if modifiers_part == "" do
          {[], class_part}
        else
          # Remove trailing colon and split by colon
          modifiers = 
            modifiers_part
            |> String.trim_trailing(":")
            |> String.split(":")
            |> Enum.reject(&(&1 == ""))
          
          {modifiers, class_part}
        end
      
      nil ->
        # Fallback - no modifiers
        {[], class}
    end
  end

  # Remove conflicting classes from the accumulator
  defp remove_conflicting_classes(acc, class_group_id, conflicting_groups, modifiers, important) do
    if class_group_id && !Enum.empty?(conflicting_groups) do
      Enum.reduce(acc, %{}, fn {key, {class, index, parsed_info}}, new_acc ->
        existing_group_id = parsed_info.class_group_id
        existing_modifiers = parsed_info.modifiers
        existing_important = parsed_info.important
        
        # Check if this existing class conflicts with the new one
        should_remove = existing_group_id && 
                       existing_modifiers == modifiers && 
                       existing_important == important &&
                       (existing_group_id in conflicting_groups || existing_group_id == class_group_id)
        
        if should_remove do
          new_acc
        else
          Map.put(new_acc, key, {class, index, parsed_info})
        end
      end)
    else
      acc
    end
  end

  # Get a unique conflict key for a parsed class
  defp get_conflict_key(parsed_info, _class_utils) do
    %{
      class_group_id: class_group_id,
      modifiers: modifiers,
      important: important
    } = parsed_info
    
    # For classes without a group (like malformed ones), use the base class as key
    base_key = class_group_id || parsed_info.base_class
    
    # Sort modifiers to ensure consistent conflict keys regardless of order
    # This makes "hover:focus:" and "focus:hover:" map to the same conflict group
    sorted_modifiers = Enum.sort(modifiers)
    modifier_key = Enum.join(sorted_modifiers, ":")
    
    case {modifier_key, important} do
      {"", false} -> base_key
      {"", true} -> "!#{base_key}"
      {mods, false} -> "#{mods}:#{base_key}"
      {mods, true} -> "!#{mods}:#{base_key}"
    end
  end
end
