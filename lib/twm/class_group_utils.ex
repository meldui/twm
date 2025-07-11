defmodule Twm.ClassGroupUtils do
  @moduledoc """
  Utilities for working with class groups in Tailwind CSS.

  This module provides functions to identify which group a class belongs to
  and to determine conflicting class groups based on the configuration.

  Uses keyword lists throughout for maintaining order.
  """

  alias Twm.Context.ClassGroupProcessingContext
  alias Twm.Config

  @type class_part_object :: [
          next_part: keyword(),
          validators: list(class_validator_object()),
          class_group_id: String.t() | atom() | nil
        ]

  @type class_validator_object :: [
          class_group_id: String.t() | atom(),
          validator: function()
        ]

  @class_part_separator "-"
  @arbitrary_property_regex ~r/^\[(.+)\]$/

  @doc """
  Creates class group utility context based on the provided configuration.

  Returns a Context struct containing the necessary data for class group operations.
  This replaces the previous approach of using anonymous functions that caused
  memory pressure by capturing large data structures.

  ## Parameters

    * `config` - Configuration keyword list containing class groups and conflicting groups

  ## Examples

      iex> config = Twm.Config.new([
      ...>   class_groups: [display: ["block", "inline"]],
      ...>   conflicting_class_groups: [display: []],
      ...>   conflicting_class_group_modifiers: [],
      ...>   theme: []
      ...> ])
      iex> context = Twm.ClassGroupUtils.create_class_group_utils(config)
      iex> Twm.ClassGroupUtils.get_class_group_id("block", context)
      "display"

  """
  @spec create_class_group_utils(Config.t()) :: ClassGroupProcessingContext.t()
  def create_class_group_utils(config) do
    class_map = create_class_map(config)
    conflicting_class_groups = Map.get(config, :conflicting_class_groups, [])

    conflicting_class_group_modifiers =
      Map.get(config, :conflicting_class_group_modifiers, [])

    %ClassGroupProcessingContext{
      class_map: class_map,
      conflicting_class_groups: conflicting_class_groups,
      conflicting_class_group_modifiers: conflicting_class_group_modifiers
    }
  end

  @doc """
  Gets the class group ID for a given class name using the context.

  ## Parameters

    * `class_name` - The class name to look up
    * `context` - The Context struct containing class group data

  ## Examples

      iex> config = Twm.Config.new([class_groups: [display: ["block"]], theme: []])
      iex> context = Twm.ClassGroupUtils.create_class_group_utils(config)
      iex> Twm.ClassGroupUtils.get_class_group_id("block", context)
      "display"

  """
  @spec get_class_group_id(String.t(), ClassGroupProcessingContext.t()) :: String.t() | nil
  def get_class_group_id(class_name, %ClassGroupProcessingContext{class_map: class_map}) do
    get_class_group_id_from_map(class_name, class_map)
  end

  @doc """
  Gets the conflicting class group IDs for a given class group.

  ## Parameters

    * `class_group_id` - The class group ID to find conflicts for
    * `has_postfix_modifier` - Whether the class has a postfix modifier
    * `context` - The Context struct containing conflict data

  ## Examples

      iex> config = Twm.Config.new([
      ...>   class_groups: [display: ["block"]],
      ...>   conflicting_class_groups: [display: ["position"]],
      ...>   conflicting_class_group_modifiers: []
      ...> ])
      iex> context = Twm.ClassGroupUtils.create_class_group_utils(config)
      iex> Twm.ClassGroupUtils.get_conflicting_class_group_ids("display", false, context)
      ["position"]

  """
  @spec get_conflicting_class_group_ids(String.t(), boolean(), ClassGroupProcessingContext.t()) ::
          [String.t()]
  def get_conflicting_class_group_ids(
        class_group_id,
        has_postfix_modifier,
        %ClassGroupProcessingContext{} = context
      ) do
    get_conflicting_class_group_ids_from_config(
      class_group_id,
      has_postfix_modifier,
      context.conflicting_class_groups,
      context.conflicting_class_group_modifiers
    )
  end

  @doc """
  Creates a class map from the configuration for efficient class lookup.

  The class map is a tree-like structure using keyword lists that allows for
  efficient traversal and lookup of class names and their corresponding groups.

  ## Examples

      iex> config = Twm.Config.new([
      ...>   class_groups: [display: ["block", "inline"]],
      ...>   theme: []
      ...> ])
      iex> class_map = Twm.ClassGroupUtils.create_class_map(config)
      iex> class_map[:next_part][:block][:class_group_id]
      "display"

  """
  @spec create_class_map(Twm.Config.t()) :: keyword()
  def create_class_map(config) do
    theme = Map.get(config, :theme, [])
    class_groups = Map.get(config, :class_groups, [])

    initial_map = [
      next_part: [],
      validators: [],
      class_group_id: nil
    ]

    Enum.reduce(class_groups, initial_map, fn {class_group_id, class_group}, acc ->
      process_class_group(class_group, acc, to_string(class_group_id), theme)
    end)
  end

  # Gets the class group ID for a given class name using the class map
  defp get_class_group_id_from_map(class_name, class_map) do
    # Check for arbitrary properties first
    case get_group_id_for_arbitrary_property(class_name) do
      nil ->
        # Handle negative values like "-inset-1"
        clean_class_name =
          if String.starts_with?(class_name, "-") do
            String.slice(class_name, 1..-1//1)
          else
            class_name
          end

        find_class_group_with_prefix_matching(clean_class_name, class_map)

      arbitrary_group_id ->
        arbitrary_group_id
    end
  end

  # Gets conflicting class group IDs for a given class group
  defp get_conflicting_class_group_ids_from_config(
         class_group_id,
         has_postfix_modifier,
         conflicting_class_groups,
         conflicting_class_group_modifiers
       ) do
    # Convert to atom for consistent lookup
    atom_key =
      if is_binary(class_group_id), do: String.to_atom(class_group_id), else: class_group_id

    conflicts = Keyword.get(conflicting_class_groups, atom_key, [])

    if has_postfix_modifier do
      modifier_conflicts = Keyword.get(conflicting_class_group_modifiers, atom_key, [])
      conflicts ++ modifier_conflicts
    else
      conflicts
    end
  end

  # Try to find class group by matching prefixes
  defp find_class_group_with_prefix_matching(class_name, class_map) do
    parts = String.split(class_name, @class_part_separator)
    find_longest_prefix_match(parts, class_map)
  end

  # Find the longest matching prefix in the class map
  defp find_longest_prefix_match(parts, class_map) do
    find_longest_prefix_match(parts, class_map, length(parts))
  end

  defp find_longest_prefix_match(parts, class_map, 0) do
    # No prefix matched, check validators at root level
    get_group_from_validators(parts, class_map)
  end

  defp find_longest_prefix_match(parts, class_map, prefix_length) do
    {prefix_parts, suffix_parts} = Enum.split(parts, prefix_length)
    prefix = Enum.join(prefix_parts, @class_part_separator)

    next_part = Keyword.get(class_map, :next_part, [])
    prefix_map = find_by_string_key(next_part, prefix)

    case prefix_map do
      nil ->
        # No match for this prefix length, try shorter prefix
        find_longest_prefix_match(parts, class_map, prefix_length - 1)

      prefix_map ->
        # Found a match for this prefix
        if Enum.empty?(suffix_parts) do
          # No suffix, check if this prefix itself is a complete class
          Keyword.get(prefix_map, :class_group_id, nil)
        else
          # There's a suffix, continue processing
          get_group_recursive(suffix_parts, prefix_map)
        end
    end
  end

  # Recursively traverse the class map to find a matching group
  defp get_group_recursive([], class_part_object) do
    Keyword.get(class_part_object, :class_group_id, nil)
  end

  defp get_group_recursive([current_class_part | rest], class_part_object) do
    case get_group_from_next_part(current_class_part, rest, class_part_object) do
      nil -> get_group_from_validators([current_class_part | rest], class_part_object)
      group -> group
    end
  end

  # Try to find group from the next part in the tree
  defp get_group_from_next_part(current_class_part, rest, class_part_object) do
    next_part = Keyword.get(class_part_object, :next_part, [])
    next_class_part_object = find_by_string_key(next_part, current_class_part)

    if next_class_part_object do
      get_group_recursive(rest, next_class_part_object)
    end
  end

  # Try to find group using validators
  defp get_group_from_validators(class_parts, class_part_object) do
    validators = Keyword.get(class_part_object, :validators, [])

    if Enum.empty?(validators) do
      nil
    else
      find_matching_validator(class_parts, validators)
    end
  end

  # Find the first validator that matches the class parts
  defp find_matching_validator(class_parts, validators) do
    class_rest = Enum.join(class_parts, @class_part_separator)

    Enum.find_value(validators, fn validator ->
      validator_func = Keyword.get(validator, :validator, nil)
      class_group_id = Keyword.get(validator, :class_group_id, nil)

      if validator_func && validator_func.(class_rest) do
        class_group_id
      end
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
    case Regex.run(@arbitrary_property_regex, class_name) do
      [_, arbitrary_property_class_name] ->
        case String.split(arbitrary_property_class_name, ":", parts: 2) do
          [property, _value] -> "arbitrary.." <> property
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # Process a class group by iterating through its definitions
  defp process_class_group(class_group, class_map, class_group_id, theme)
       when is_list(class_group) do
    # Separate different types of definitions
    {literals, others} = Enum.split_with(class_group, &(is_binary(&1) and &1 != ""))

    # Process literals first
    class_map_with_literals =
      Enum.reduce(literals, class_map, fn class_definition, acc ->
        add_class_definition_to_map(class_definition, acc, class_group_id, theme)
      end)

    # Find common prefix for validator placement
    common_prefix = find_common_prefix(literals)

    # Process other definitions
    Enum.reduce(others, class_map_with_literals, fn class_definition, acc ->
      if is_function(class_definition) and !theme_getter?(class_definition) do
        add_validator_to_map(class_definition, acc, class_group_id, common_prefix)
      else
        add_class_definition_to_map(class_definition, acc, class_group_id, theme)
      end
    end)
  end

  defp process_class_group(class_group, class_map, class_group_id, theme) do
    add_class_definition_to_map(class_group, class_map, class_group_id, theme)
  end

  # Add a single class definition to the class map
  defp add_class_definition_to_map("", class_map, class_group_id, _theme) do
    # Empty string means this is the root class group
    Keyword.put(class_map, :class_group_id, class_group_id)
  end

  defp add_class_definition_to_map(class_definition, class_map, class_group_id, _theme)
       when is_binary(class_definition) do
    add_class_path_to_map(class_map, class_definition, class_group_id)
  end

  defp add_class_definition_to_map(class_definition, class_map, class_group_id, theme)
       when is_function(class_definition) do
    if theme_getter?(class_definition) do
      # Theme getter - call it and process the result
      theme_result = Twm.Config.Theme.call_theme_getter(class_definition, theme)
      process_class_group(theme_result, class_map, class_group_id, theme)
    else
      # Regular validator function
      validator = [
        validator: class_definition,
        class_group_id: class_group_id
      ]

      validators = Keyword.get(class_map, :validators, [])
      Keyword.put(class_map, :validators, validators ++ [validator])
    end
  end

  # Handle ThemeGetter structs
  defp add_class_definition_to_map(
         %Twm.Config.Theme.ThemeGetter{} = class_definition,
         class_map,
         class_group_id,
         theme
       ) do
    theme_result = Twm.Config.Theme.call_theme_getter(class_definition, theme)
    process_class_group(theme_result, class_map, class_group_id, theme)
  end

  # Handle nested structures (keyword lists)
  defp add_class_definition_to_map(class_definition, class_map, class_group_id, theme)
       when is_list(class_definition) do
    Enum.reduce(class_definition, class_map, fn {key, nested_group}, acc ->
      key_string = to_string(key)

      # Add the key as a path in the class map
      updated_map = add_class_path_to_map(acc, key_string, nil)

      # Get the target object at this path
      target_object = get_at_path(updated_map, key_string)

      # Process the nested group at this location
      updated_target = process_class_group(nested_group, target_object, class_group_id, theme)

      # Put the updated target back
      put_at_path(updated_map, key_string, updated_target)
    end)
  end

  # Handle nested structures (maps)
  defp add_class_definition_to_map(class_definition, class_map, class_group_id, theme)
       when is_map(class_definition) do
    Enum.reduce(class_definition, class_map, fn {key, nested_group}, acc ->
      key_string = to_string(key)

      # Add the key as a path in the class map
      updated_map = add_class_path_to_map(acc, key_string, nil)

      # Get the target object at this path
      target_object = get_at_path(updated_map, key_string)

      # Process the nested group at this location
      updated_target = process_class_group(nested_group, target_object, class_group_id, theme)

      # Put the updated target back
      put_at_path(updated_map, key_string, updated_target)
    end)
  end

  # Handle tuple case
  defp add_class_definition_to_map({key, nested_group}, class_map, class_group_id, theme) do
    key_string = to_string(key)
    updated_map = ensure_path_exists(class_map, key_string)

    target_object = get_at_path(updated_map, key_string)
    updated_target = process_class_group(nested_group, target_object, class_group_id, theme)

    put_at_path(updated_map, key_string, updated_target)
  end

  # Add a class path to the class map
  defp add_class_path_to_map(class_map, class_path, class_group_id) do
    path_parts =
      if class_group_id == nil do
        [class_path]
      else
        parts = String.split(class_path, @class_part_separator)
        # Handle negative classes
        if List.first(parts) == "" and length(parts) > 1 do
          tl(parts)
        else
          parts
        end
      end

    add_path_parts_to_map(class_map, path_parts, class_group_id)
  end

  # Recursively add path parts to the map
  defp add_path_parts_to_map(class_map, [], class_group_id) do
    if class_group_id do
      Keyword.put(class_map, :class_group_id, class_group_id)
    else
      class_map
    end
  end

  defp add_path_parts_to_map(class_map, [part | rest], class_group_id) do
    next_part = Keyword.get(class_map, :next_part, [])

    existing_or_new =
      case find_by_string_key(next_part, part) do
        nil ->
          [
            next_part: [],
            validators: [],
            class_group_id: nil
          ]

        existing ->
          existing
      end

    updated_nested = add_path_parts_to_map(existing_or_new, rest, class_group_id)
    # Remove existing entry with same string key if it exists
    filtered_next_part = remove_by_string_key(next_part, part)
    # Add new entry with string as atom key
    updated_next_part = [{String.to_atom(part), updated_nested} | filtered_next_part]

    Keyword.put(class_map, :next_part, updated_next_part)
  end

  # Ensure a path exists in the class map
  defp ensure_path_exists(class_map, path) do
    next_part = Keyword.get(class_map, :next_part, [])

    path_exists = find_by_string_key(next_part, path) != nil

    if path_exists do
      class_map
    else
      new_part = [
        next_part: [],
        validators: [],
        class_group_id: nil
      ]

      atom_path = String.to_atom(path)
      updated_next_part = [{atom_path, new_part} | next_part]
      Keyword.put(class_map, :next_part, updated_next_part)
    end
  end

  # Get object at a specific path
  defp get_at_path(class_map, path) do
    next_part = Keyword.get(class_map, :next_part, [])

    case find_by_string_key(next_part, path) do
      nil ->
        [
          next_part: [],
          validators: [],
          class_group_id: nil
        ]

      existing ->
        existing
    end
  end

  # Put object at a specific path
  defp put_at_path(class_map, path, object) do
    next_part = Keyword.get(class_map, :next_part, [])
    # Remove existing entry with same string key if it exists
    filtered_next_part = remove_by_string_key(next_part, path)
    # Add new entry with string as atom key
    atom_path = String.to_atom(path)
    updated_next_part = [{atom_path, object} | filtered_next_part]
    Keyword.put(class_map, :next_part, updated_next_part)
  end

  # Find common prefix from a list of class names
  defp find_common_prefix([]), do: ""
  defp find_common_prefix([single]), do: extract_prefix(single)

  defp find_common_prefix(class_names) do
    prefixes = Enum.map(class_names, &extract_prefix/1)

    # Find the most frequent prefix
    prefixes
    |> Enum.frequencies()
    |> Enum.max_by(fn {_prefix, count} -> count end, fn -> {"", 0} end)
    |> elem(0)
  end

  # Extract prefix from a class name
  defp extract_prefix(class_name) do
    case String.split(class_name, @class_part_separator, parts: 2) do
      [prefix, _] -> prefix
      [_] -> ""
    end
  end

  # Add a validator to the appropriate level in the class map
  defp add_validator_to_map(validator_function, class_map, class_group_id, "") do
    # No common prefix, add to root level
    validator = [
      validator: validator_function,
      class_group_id: class_group_id
    ]

    validators = Keyword.get(class_map, :validators, [])
    Keyword.put(class_map, :validators, validators ++ [validator])
  end

  defp add_validator_to_map(validator_function, class_map, class_group_id, prefix) do
    prefix_parts = String.split(prefix, @class_part_separator)
    add_validator_to_path(class_map, prefix_parts, validator_function, class_group_id)
  end

  # Add validator following the path structure
  defp add_validator_to_path(class_map, [], validator_function, class_group_id) do
    validator = [
      validator: validator_function,
      class_group_id: class_group_id
    ]

    validators = Keyword.get(class_map, :validators, [])
    Keyword.put(class_map, :validators, validators ++ [validator])
  end

  defp add_validator_to_path(class_map, [part | rest], validator_function, class_group_id) do
    updated_map = ensure_path_exists(class_map, part)

    part_object = get_at_path(updated_map, part)
    updated_part = add_validator_to_path(part_object, rest, validator_function, class_group_id)

    put_at_path(updated_map, part, updated_part)
  end

  # Check if a function is a theme getter
  defp theme_getter?(value) do
    Twm.Config.Theme.theme_getter?(value)
  end

  # Helper function to find value by string key in keyword list
  defp find_by_string_key(keyword_list, string_key) do
    Enum.find_value(keyword_list, fn {key, value} ->
      if to_string(key) == string_key, do: value
    end)
  end

  # Helper function to remove entry by string key from keyword list
  defp remove_by_string_key(keyword_list, string_key) do
    Enum.reject(keyword_list, fn {key, _value} -> to_string(key) == string_key end)
  end
end
