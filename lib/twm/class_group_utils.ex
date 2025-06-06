defmodule Twm.ClassGroupUtils do
  @moduledoc """
  Utilities for working with class groups in Tailwind CSS.

  This module provides functions to identify which group a class belongs to
  and to determine conflicting class groups based on the configuration.
  """

  @type class_part_object :: %{
          next_part: map(),
          validators: list(class_validator_object()),
          class_group_id: String.t() | atom() | nil
        }

  @type class_validator_object :: %{
          class_group_id: String.t() | atom(),
          validator: function()
        }

  @class_part_separator "-"
  @arbitrary_property_regex ~r/^\[(.+)\]$/

  @doc """
  Creates class group utility functions based on the provided configuration.

  Returns a map containing:
  - `get_class_group_id/1` - Function to get the class group ID for a class name
  - `get_conflicting_class_group_ids/2` - Function to get conflicting groups

  ## Parameters

    * `config` - Configuration map containing class groups and conflicting groups

  ## Examples

      iex> config = %{
      ...>   class_groups: %{display: ["block", "inline"]},
      ...>   conflicting_class_groups: %{display: []},
      ...>   conflicting_class_group_modifiers: %{},
      ...>   theme: %{}
      ...> }
      iex> utils = Twm.ClassGroupUtils.create_class_group_utils(config)
      iex> utils.get_class_group_id.("block")
      "display"

  """
  @spec create_class_group_utils(map()) :: map()
  def create_class_group_utils(config) do
    class_map = create_class_map(config)
    conflicting_class_groups = Map.get(config, :conflicting_class_groups, %{})
    conflicting_class_group_modifiers = Map.get(config, :conflicting_class_group_modifiers, %{})

    get_class_group_id = fn class_name ->
      get_class_group_id(class_name, class_map)
    end

    get_conflicting_class_group_ids = fn class_group_id, has_postfix_modifier ->
      get_conflicting_class_group_ids(
        class_group_id,
        has_postfix_modifier,
        conflicting_class_groups,
        conflicting_class_group_modifiers
      )
    end

    %{
      get_class_group_id: get_class_group_id,
      get_conflicting_class_group_ids: get_conflicting_class_group_ids
    }
  end

  @doc """
  Creates a class map from the configuration for efficient class lookup.

  The class map is a tree-like structure that allows for efficient traversal
  and lookup of class names and their corresponding groups.

  ## Examples

      iex> config = %{
      ...>   class_groups: %{display: ["block", "inline"]},
      ...>   theme: %{}
      ...> }
      iex> class_map = Twm.ClassGroupUtils.create_class_map(config)
      iex> class_map.next_part["block"].class_group_id
      "display"

  """
  @spec create_class_map(map()) :: class_part_object()
  def create_class_map(config) do
    theme = Map.get(config, :theme, %{})
    class_groups = Map.get(config, :class_groups, %{})

    initial_map = %{
      next_part: %{},
      validators: [],
      class_group_id: nil
    }

    Enum.reduce(class_groups, initial_map, fn {class_group_id, class_group}, acc ->
      process_class_group(class_group, acc, to_string(class_group_id), theme)
    end)
  end

  # Gets the class group ID for a given class name using the class map
  defp get_class_group_id(class_name, class_map) do
    # Check for arbitrary properties first, before splitting by dash
    case get_group_id_for_arbitrary_property(class_name) do
      nil ->
        # Not an arbitrary property, proceed with normal processing
        class_parts = String.split(class_name, @class_part_separator)

        # Handle negative values like "-inset-1"
        class_parts =
          if List.first(class_parts) == "" and length(class_parts) > 1 do
            tl(class_parts)
          else
            class_parts
          end

        get_group_recursive(class_parts, class_map)
      
      arbitrary_group_id ->
        # It's an arbitrary property
        arbitrary_group_id
    end
  end

  # Gets conflicting class group IDs for a given class group
  defp get_conflicting_class_group_ids(
         class_group_id,
         has_postfix_modifier,
         conflicting_class_groups,
         conflicting_class_group_modifiers
       ) do
    # Try both string and atom keys for lookup
    atom_key =
      if is_binary(class_group_id), do: String.to_atom(class_group_id), else: class_group_id

    string_key = to_string(class_group_id)

    conflicts =
      Map.get(conflicting_class_groups, atom_key, []) ++
        Map.get(conflicting_class_groups, string_key, [])

    if has_postfix_modifier do
      modifier_conflicts =
        Map.get(conflicting_class_group_modifiers, atom_key, []) ++
          Map.get(conflicting_class_group_modifiers, string_key, [])

      conflicts ++ modifier_conflicts
    else
      conflicts
    end
  end

  # Recursively traverse the class map to find a matching group
  defp get_group_recursive([], class_part_object) do
    Map.get(class_part_object, :class_group_id)
  end

  defp get_group_recursive([current_class_part | rest], class_part_object) do
    case get_group_from_next_part(current_class_part, rest, class_part_object) do
      nil -> get_group_from_validators([current_class_part | rest], class_part_object)
      group -> group
    end
  end

  # Try to find group from the next part in the tree
  defp get_group_from_next_part(current_class_part, rest, class_part_object) do
    next_part = Map.get(class_part_object, :next_part, %{})
    next_class_part_object = Map.get(next_part, current_class_part)

    if next_class_part_object do
      get_group_recursive(rest, next_class_part_object)
    end
  end

  # Try to find group using validators
  defp get_group_from_validators(class_parts, class_part_object) do
    validators = Map.get(class_part_object, :validators, [])

    case validators do
      [] -> nil
      _ -> find_matching_validator(class_parts, validators)
    end
  end

  # Find the first validator that matches the class parts
  defp find_matching_validator(class_parts, validators) do
    class_rest = Enum.join(class_parts, @class_part_separator)

    Enum.find_value(validators, fn %{validator: validator, class_group_id: class_group_id} ->
      if validator.(class_rest), do: class_group_id
    end)
  end

  # Handle arbitrary properties like [color:red]
  defp get_group_id_for_arbitrary_property(class_name) do
    if Regex.match?(@arbitrary_property_regex, class_name) do
      extract_arbitrary_property(class_name)
    end
  end

  # Extract property from arbitrary property syntax
  defp extract_arbitrary_property(class_name) do
    captures = Regex.run(@arbitrary_property_regex, class_name)

    if captures && length(captures) > 1 do
      arbitrary_property_class_name = Enum.at(captures, 1)

      case String.split(arbitrary_property_class_name, ":", parts: 2) do
        [property, _value] -> "arbitrary.." <> property
        _ -> nil
      end
    end
  end

  # Process a class group by iterating through its definitions
  defp process_class_group(class_group, class_map, class_group_id, theme)
       when is_list(class_group) do
    Enum.reduce(class_group, class_map, fn class_definition, acc ->
      add_class_definition_to_map(class_definition, acc, class_group_id, theme)
    end)
  end

  # Handle the case where class_group is not a list (edge case)
  defp process_class_group(class_group, class_map, class_group_id, theme) do
    add_class_definition_to_map(class_group, class_map, class_group_id, theme)
  end

  # Add a single class definition to the class map
  defp add_class_definition_to_map(class_definition, class_map, class_group_id, _theme)
       when is_binary(class_definition) do
    if class_definition == "" do
      # Empty string means this is the root class group
      %{class_map | class_group_id: class_group_id}
    else
      # Add the class to the appropriate path in the tree
      add_class_path_to_map(class_map, class_definition, class_group_id)
    end
  end

  defp add_class_definition_to_map(class_definition, class_map, class_group_id, theme)
       when is_function(class_definition) do
    if theme_getter?(class_definition) do
      # Theme getter - call it and process the result
      theme_result = Twm.Config.Theme.call_theme_getter(class_definition, theme)
      process_class_group(theme_result, class_map, class_group_id, theme)
    else
      # Regular validator function
      validator = %{
        validator: class_definition,
        class_group_id: class_group_id
      }

      validators = Map.get(class_map, :validators, [])
      Map.put(class_map, :validators, [validator | validators])
    end
  end

  # Handle ThemeGetter structs specifically
  defp add_class_definition_to_map(%Twm.Config.Theme.ThemeGetter{} = class_definition, class_map, class_group_id, theme) do
    # Theme getter struct - call it and process the result
    theme_result = Twm.Config.Theme.call_theme_getter(class_definition, theme)
    process_class_group(theme_result, class_map, class_group_id, theme)
  end

  defp add_class_definition_to_map(class_definition, class_map, class_group_id, theme)
       when is_map(class_definition) do
    # Process nested map structure
    Enum.reduce(class_definition, class_map, fn {key, nested_group}, acc ->
      # Create or get the path for this key
      key_string = to_string(key)
      updated_map = ensure_path_exists(acc, key_string)

      # Get the target object at this path
      target_object = get_at_path(updated_map, key_string)

      # Process the nested group
      updated_target = process_class_group(nested_group, target_object, class_group_id, theme)

      # Put the updated target back
      put_at_path(updated_map, key_string, updated_target)
    end)
  end

  # Handle the case where we get a list containing tuples (which can happen with nested maps)
  defp add_class_definition_to_map({key, nested_group}, class_map, class_group_id, theme) do
    # Create or get the path for this key
    key_string = to_string(key)
    updated_map = ensure_path_exists(class_map, key_string)

    # Get the target object at this path
    target_object = get_at_path(updated_map, key_string)

    # Process the nested group
    updated_target = process_class_group(nested_group, target_object, class_group_id, theme)

    # Put the updated target back
    put_at_path(updated_map, key_string, updated_target)
  end

  # Add a class path (like "space-x-1") to the class map
  defp add_class_path_to_map(class_map, class_path, class_group_id) do
    path_parts = String.split(class_path, @class_part_separator)

    # Handle negative classes by removing the leading empty string
    path_parts =
      if List.first(path_parts) == "" and length(path_parts) > 1 do
        tl(path_parts)
      else
        path_parts
      end

    add_path_parts_to_map(class_map, path_parts, class_group_id)
  end

  # Recursively add path parts to the map
  defp add_path_parts_to_map(class_map, [], class_group_id) do
    %{class_map | class_group_id: class_group_id}
  end

  defp add_path_parts_to_map(class_map, [part | rest], class_group_id) do
    next_part = Map.get(class_map, :next_part, %{})

    existing_or_new =
      Map.get(next_part, part, %{
        next_part: %{},
        validators: [],
        class_group_id: nil
      })

    updated_nested = add_path_parts_to_map(existing_or_new, rest, class_group_id)
    updated_next_part = Map.put(next_part, part, updated_nested)

    %{class_map | next_part: updated_next_part}
  end

  # Ensure a path exists in the class map
  defp ensure_path_exists(class_map, path) do
    next_part = Map.get(class_map, :next_part, %{})

    if Map.has_key?(next_part, path) do
      class_map
    else
      new_part = %{
        next_part: %{},
        validators: [],
        class_group_id: nil
      }

      updated_next_part = Map.put(next_part, path, new_part)
      %{class_map | next_part: updated_next_part}
    end
  end

  # Get object at a specific path
  defp get_at_path(class_map, path) do
    get_in(class_map, [:next_part, path]) ||
      %{
        next_part: %{},
        validators: [],
        class_group_id: nil
      }
  end

  # Put object at a specific path
  defp put_at_path(class_map, path, object) do
    next_part = Map.get(class_map, :next_part, %{})
    updated_next_part = Map.put(next_part, path, object)
    %{class_map | next_part: updated_next_part}
  end

  # Check if a function is a theme getter
  # Theme getters in Elixir are identified by the ThemeGetter struct
  defp theme_getter?(value) do
    Twm.Config.Theme.theme_getter?(value)
  end
end
