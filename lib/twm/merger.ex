defmodule Twm.Merger do
  @moduledoc """
  Handles the core class merging logic for Twm.

  This module provides functions to merge Tailwind CSS classes, handling conflicts
  based on the provided configuration.
  """

  alias Twm.ClassGroupUtils
  alias Twm.Parser.ClassName
  alias Twm.SortModifiers

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
  @spec merge_classes(
          String.t(),
          Twm.Config.t(),
          Twm.Context.ClassGroupProcessingContext.t() | nil
        ) ::
          String.t()
  def merge_classes(classes, config, class_utils_context \\ nil)

  def merge_classes("", _, _), do: ""

  def merge_classes(classes, %Twm.Config{} = config, nil)
      when is_binary(classes) do
    class_list = String.split(classes, ~r/\s+/, trim: true)

    class_utils_context = ClassGroupUtils.create_class_group_utils(config)

    # Create class name parser context for the config
    parse_class_name_context = ClassName.create_parse_class_name(config)

    # Parse classes and merge conflicts
    merge_class_list(class_list, class_utils_context, parse_class_name_context, config)
  end

  def merge_classes(classes, %Twm.Config{} = config, class_utils_context)
      when is_binary(classes) do
    class_list = String.split(classes, ~r/\s+/, trim: true)

    # Create class name parser context for the config
    parse_class_name_context = ClassName.create_parse_class_name(config)

    # Parse classes and merge conflicts
    merge_class_list(class_list, class_utils_context, parse_class_name_context, config)
  end

  # Merge a list of classes using the class utilities context
  defp merge_class_list(class_list, class_utils_context, parse_class_name_context, config) do
    # Parse each class and track conflicts
    parsed_classes =
      Enum.map(
        class_list,
        &parse_class_with_modifiers(&1, class_utils_context, parse_class_name_context, config)
      )

    # Group by conflict keys and handle conflicting class groups
    result_map =
      parsed_classes
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{class, parsed_info}, index}, acc ->
        class_group_id = parsed_info.class_group_id
        modifiers = parsed_info.modifiers
        important = parsed_info.important

        # Create the primary conflict key for this class
        conflict_key = get_conflict_key(parsed_info, class_utils_context)

        # Get all conflicting class group IDs
        has_postfix_modifier = Map.get(parsed_info, :has_postfix_modifier, false)

        conflicting_groups =
          if class_group_id do
            ClassGroupUtils.get_conflicting_class_group_ids(
              class_group_id,
              has_postfix_modifier,
              class_utils_context
            )
          else
            []
          end

        # Remove any existing classes that conflict with this one
        updated_acc =
          remove_conflicting_classes(
            acc,
            class_group_id,
            conflicting_groups,
            modifiers,
            important
          )

        # Add this class to the map
        Map.put(updated_acc, conflict_key, {class, index, parsed_info})
      end)

    # Sort by original index to maintain order and extract classes
    result_map
    |> Map.values()
    |> Enum.sort_by(fn {_class, index, _parsed} -> index end)
    |> Enum.map_join(" ", fn {class, _index, _parsed} -> class end)
  end

  # Parse a class with its modifiers and important flag
  defp parse_class_with_modifiers(class, class_utils_context, parse_class_name_context, config) do
    # First, try to get the class group ID from the original class
    original_class_group_id =
      ClassGroupUtils.get_class_group_id(class, class_utils_context)

    # Use the context-based parser
    parsed_class_name = ClassName.parse_class_name(class, parse_class_name_context)

    # Check if we're using an experimental parser by comparing with basic parsing
    basic_parsed = ClassName.do_parse_class_name(class)
    using_experimental_parser = parsed_class_name != basic_parsed

    # Handle external classes
    if Map.get(parsed_class_name, :is_external, false) do
      # For external classes, use the original class name as-is
      parsed_info = %{
        class_group_id: nil,
        modifiers: [],
        important: false,
        base_class: class,
        original_class: class,
        has_postfix_modifier: false
      }

      {class, parsed_info}
    else
      modifiers = sort_modifiers_with_config(Map.get(parsed_class_name, :modifiers, []), config)
      important = Map.get(parsed_class_name, :has_important_modifier, false)
      base_class = Map.get(parsed_class_name, :base_class_name, class)
      has_postfix_modifier = Map.get(parsed_class_name, :maybe_postfix_modifier_position) != nil

      # Get class group ID based on the base class (which may have been transformed)
      transformed_class_group_id =
        ClassGroupUtils.get_class_group_id(base_class, class_utils_context)

      # Use original class group ID if the transformed class isn't recognized
      # This preserves conflict resolution for experimental parsers
      class_group_id =
        if transformed_class_group_id do
          transformed_class_group_id
        else
          original_class_group_id
        end

      # Determine output class name based on experimental parser behavior
      output_class =
        if using_experimental_parser do
          # Check if the experimental parser made meaningful transformations
          base_class_changed = base_class != class
          important_changed = important != basic_parsed.has_important_modifier

          # For modifiers, check if any new modifiers were added or removed
          # (don't care about order since that's handled by conflict resolution)
          original_modifier_set = MapSet.new(basic_parsed.modifiers)
          new_modifier_set = MapSet.new(modifiers)
          modifiers_changed = original_modifier_set != new_modifier_set

          parser_transformed = base_class_changed or important_changed or modifiers_changed

          if parser_transformed do
            # Experimental parser transformed the class - use the transformed result
            reconstruct_class_name(modifiers, base_class, important, config)
          else
            # No transformation - use original class
            class
          end
        else
          # No experimental parser - use original class
          class
        end

      parsed_info = %{
        class_group_id: class_group_id,
        modifiers: modifiers,
        important: important,
        base_class: base_class,
        original_class: class,
        has_postfix_modifier: has_postfix_modifier
      }

      {output_class, parsed_info}
    end
  end

  # Reconstruct a class name from its parsed components
  defp reconstruct_class_name(modifiers, base_class, important, config) do
    modifier_prefix =
      if Enum.empty?(modifiers) do
        ""
      else
        Enum.join(modifiers, ":") <> ":"
      end

    important_prefix = if important, do: "!", else: ""

    # Add prefix if configured
    prefix_str =
      case Map.get(config, :prefix) do
        nil -> ""
        "" -> ""
        prefix -> prefix <> ":"
      end

    case prefix_str do
      "" -> important_prefix <> modifier_prefix <> base_class
      _ -> prefix_str <> modifier_prefix <> base_class <> important_prefix
    end
  end

  # Remove conflicting classes from the accumulator
  defp remove_conflicting_classes(acc, class_group_id, conflicting_groups, modifiers, important) do
    if class_group_id do
      Enum.reduce(acc, %{}, fn {key, {class, index, parsed_info}}, new_acc ->
        existing_group_id = parsed_info.class_group_id
        existing_modifiers = parsed_info.modifiers
        existing_important = parsed_info.important

        # Check if this existing class conflicts with the new one

        should_remove =
          existing_group_id &&
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
  defp get_conflict_key(parsed_info, _class_utils_context) do
    %{
      class_group_id: class_group_id,
      modifiers: modifiers,
      important: important
    } = parsed_info

    # For experimental parser results with same base class, use base class as conflict key
    # This ensures that multiple instances of the same transformed class conflict
    base_key =
      if class_group_id do
        class_group_id
      else
        # For unrecognized classes, use the base class name to ensure conflicts
        parsed_info.base_class
      end

    # Handle wildcard position sensitivity for conflict key generation
    modifier_key = Enum.join(modifiers)

    case {modifier_key, important} do
      {"", false} -> base_key
      {"", true} -> "!#{base_key}"
      {mods, false} -> "#{mods}:#{base_key}"
      {mods, true} -> "!#{mods}:#{base_key}"
    end
  end

  # Determines if wildcard position affects conflict resolution
  # Returns true if wildcards are in different relative positions that should be preserved
  defp wildcard_position_affects_conflicts?(modifiers) do
    wildcard_index = Enum.find_index(modifiers, &(&1 == "*"))

    if wildcard_index do
      # Check if wildcard is at beginning or end (position-sensitive cases)
      wildcard_index == 0 or wildcard_index == length(modifiers) - 1
    else
      false
    end
  end

  # Sort modifiers using proper SortModifiers logic with the provided config
  defp sort_modifiers_with_config(modifiers, config) do
    sort_context = SortModifiers.create_sort_modifiers(config)
    # Check if this is a case where wildcard position matters for conflicts
    if Enum.any?(modifiers, &(&1 == "*")) && wildcard_position_affects_conflicts?(modifiers) do
      modifiers
    else
      # Use proper sorting logic for wildcards in same relative position
      SortModifiers.sort_modifiers(modifiers, sort_context)
    end
  end
end
