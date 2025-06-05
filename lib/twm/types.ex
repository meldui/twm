defmodule Twm.Types do
  @moduledoc """
  Common types used throughout the Twm library.
  """

  @typedoc """
  Represents a parsed class name with its components.

  * `:modifiers` - List of modifiers applied to the class (e.g., "hover", "focus", "dark")
  * `:has_important_modifier` - Boolean indicating if the class has the important modifier
  * `:base_class_name` - The core class name without modifiers
  * `:maybe_postfix_modifier_position` - Position of a postfix modifier if present
  * `:is_external` - Whether the class is external to Tailwind (when prefix doesn't match)
  """
  @type parsed_class_name :: %{
          modifiers: [String.t()],
          has_important_modifier: boolean(),
          base_class_name: String.t(),
          maybe_postfix_modifier_position: non_neg_integer() | nil,
          is_external: boolean() | nil
        }

  @typedoc """
  Configuration for the Twm library.

  * `:prefix` - Optional prefix for Tailwind classes
  * `:theme` - Theme configuration
  * `:class_groups` - Class group definitions
  * `:conflicting_class_groups` - Groups of class names that conflict with each other
  * `:cache_size` - Size of the LRU cache (if enabled)
  * `:experimental_parse_class_name` - Optional experimental class name parser function
  """
  @type config :: %{
          optional(:cache_name) => atom() | String.t(),
          optional(:prefix) => String.t(),
          optional(:theme) => map(),
          optional(:class_groups) => map(),
          optional(:conflicting_class_groups) => map(),
          optional(:cache_size) => non_neg_integer(),
          optional(:experimental_parse_class_name) => (map() -> parsed_class_name())
        }
end
