defmodule Twm.Context.ClassParsingContext do
  @moduledoc """
  Context structure for class name parsing operations.

  This struct holds the configuration data needed for class name parsing operations,
  replacing the anonymous functions that were causing memory pressure by
  capturing configuration data in their closures.

  Used by the Parser.ClassName module to efficiently parse class names
  with proper prefix handling and experimental parsing features.
  """

  defstruct [
    :prefix,
    :experimental_parse_class_name
  ]

  @type t :: %__MODULE__{
          prefix: String.t() | nil,
          experimental_parse_class_name: function() | nil
        }
end
