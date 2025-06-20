defmodule Twm.Context.ClassGroupProcessingContext do
  @moduledoc """
  Context structure for class group processing operations.

  This struct holds the configuration data needed for class group operations,
  replacing the anonymous functions that were causing memory pressure by
  capturing large data structures in their closures.

  Used by the ClassGroupUtils module to efficiently process class groups
  and determine conflicts between classes.
  """

  defstruct [
    :class_map,
    :conflicting_class_groups,
    :conflicting_class_group_modifiers
  ]

  @type t :: %__MODULE__{
          class_map: map(),
          conflicting_class_groups: keyword(),
          conflicting_class_group_modifiers: keyword()
        }
end
