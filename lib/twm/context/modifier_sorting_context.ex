defmodule Twm.Context.ModifierSortingContext do
  @moduledoc """
  Context structure for modifier sorting operations.

  This struct holds the configuration data needed for modifier sorting operations,
  replacing the anonymous functions that were causing memory pressure by
  capturing configuration data in their closures.

  Used by the SortModifiers module to efficiently sort modifiers while
  preserving the order of order-sensitive modifiers and arbitrary variants.
  """

  defstruct [
    :order_sensitive_modifiers_set
  ]

  @type t :: %__MODULE__{
          order_sensitive_modifiers_set: MapSet.t()
        }
end
