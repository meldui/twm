defmodule Twm.Validators do
  @moduledoc """
  Provides functions for validating Tailwind CSS class values.

  Port of the TypeScript validators in tailwind-merge.
  """

  # Regular expressions
  @arbitrary_value_regex ~r/^\[(?:([a-z][\w-]*):)?(.+)\]$/i
  @arbitrary_variable_regex ~r/^\((?:([a-z][\w-]*):)?(.+)\)$/i
  @fraction_regex ~r/^\d+\/\d+$/
  @tshirt_unit_regex ~r/^(\d+(\.\d+)?)?(xs|sm|md|lg|xl)$/
  @length_unit_regex ~r/\d+(%|px|r?em|[sdl]?v([hwib]|min|max)|pt|pc|in|cm|mm|cap|ch|ex|r?lh|cq(w|h|i|b|min|max))|\b(calc|min|max|clamp)\(.+\)|^0$/
  @color_function_regex ~r/^(rgba?|hsla?|hwb|(ok)?(lab|lch))\(.+\)$/
  # Shadow always begins with x and y offset separated by underscore optionally prepended by inset
  @shadow_regex ~r/^(inset_)?-?((\d+)?\.?(\d+)[a-z]+|0)_-?((\d+)?\.?(\d+)[a-z]+|0)/
  @image_regex ~r/^(url|image|image-set|cross-fade|element|(repeating-)?(linear|radial|conic)-gradient)\(.+\)$/

  @doc """
  Returns true if the value is a fraction (e.g., "1/2").
  """
  @spec is_fraction(String.t()) :: boolean()
  def is_fraction(value) when is_binary(value) do
    Regex.match?(@fraction_regex, value)
  end

  @doc """
  Returns true if the value is a number.
  """
  @spec is_number_value(String.t()) :: boolean()
  def is_number_value(value) when is_binary(value) do
    case Float.parse(value) do
      {_num, ""} -> true
      _ -> false
    end
  end

  @doc """
  Returns true if the value is an integer.
  """
  @spec is_integer_value(String.t()) :: boolean()
  def is_integer_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {_num, ""} -> true
      _ -> false
    end
  end

  @doc """
  Returns true if the value is a percentage.
  """
  @spec percent?(String.t()) :: boolean()
  def percent?(value) when is_binary(value) do
    if String.ends_with?(value, "%") do
      case String.slice(value, 0..-2//1) do
        "" ->
          false

        # Handle ".01%" case by prepending a zero
        "." <> rest ->
          is_number_value("0." <> rest)

        str ->
          is_number_value(str)
      end
    else
      false
    end
  end

  def percent?(_), do: false

  @doc """
  Returns true if the value is a t-shirt size (e.g., "xs", "sm", "md", "lg", "xl", "2xl").
  """
  @spec is_tshirt_size(String.t()) :: boolean()
  def is_tshirt_size(value) when is_binary(value) do
    Regex.match?(@tshirt_unit_regex, value)
  end

  @doc """
  Always returns true. Used for validators that accept any value.
  """
  @spec any? :: boolean()
  def any?, do: true
  def any?(_), do: true

  @spec is_length_only(String.t()) :: boolean()
  defp is_length_only(value) when is_binary(value) do
    Regex.match?(@length_unit_regex, value) and not Regex.match?(@color_function_regex, value)
  end

  # Always returns false - used as a placeholder for validators that reject all values
  @spec never?(any) :: boolean()
  defp never?(_), do: false

  # Determines if a value is a valid CSS shadow
  @spec is_shadow(String.t()) :: boolean()
  defp is_shadow(value) when is_binary(value), do: Regex.match?(@shadow_regex, value)

  # Determines if a value is a valid CSS image
  @spec is_image(String.t()) :: boolean()
  defp is_image(value) when is_binary(value), do: Regex.match?(@image_regex, value)

  @doc """
  Returns true if the value is not an arbitrary value or variable.
  """
  @spec is_any_non_arbitrary(String.t()) :: boolean()
  def is_any_non_arbitrary(value) when is_binary(value) do
    not is_arbitrary_value(value) and not is_arbitrary_variable(value)
  end

  @doc """
  Returns true if the value is an arbitrary size (e.g., "[size:10px]").
  """
  @spec is_arbitrary_size(String.t()) :: boolean()
  def is_arbitrary_size(value) when is_binary(value) do
    get_is_arbitrary_value(value, &is_label_size/1, &never?/1)
  end

  @doc """
  Returns true if the value is an arbitrary value (e.g., "[value]").
  """
  @spec is_arbitrary_value(String.t()) :: boolean()
  def is_arbitrary_value(value) when is_binary(value) do
    Regex.match?(@arbitrary_value_regex, value)
  end

  @doc """
  Returns true if the value is an arbitrary length (e.g., "[10px]").
  """
  @spec is_arbitrary_length(String.t()) :: boolean()
  def is_arbitrary_length(value) when is_binary(value),
    do: get_is_arbitrary_value(value, &is_label_length/1, &is_length_only/1)

  @doc """
  Returns true if the value is an arbitrary number (e.g., "[10]").
  """
  @spec is_arbitrary_number(String.t()) :: boolean()
  def is_arbitrary_number(value) when is_binary(value) do
    get_is_arbitrary_value(value, &is_label_number/1, &is_number_value/1)
  end

  @doc """
  Returns true if the value is an arbitrary position (e.g., "[position:center]").
  """
  @spec is_arbitrary_position(String.t()) :: boolean()
  def is_arbitrary_position(value) when is_binary(value) do
    get_is_arbitrary_value(value, &is_label_position/1, &never?/1)
  end

  @doc """
  Returns true if the value is an arbitrary image (e.g., "[url:var(--my-url)]").
  """
  @spec is_arbitrary_image(String.t()) :: boolean()
  def is_arbitrary_image(value) when is_binary(value),
    do: get_is_arbitrary_value(value, &is_label_image/1, &is_image/1)

  @doc """
  Returns true if the value is an arbitrary shadow (e.g., "[0_35px_60px_-15px_rgba(0,0,0,0.3)]").
  """
  @spec is_arbitrary_shadow(String.t()) :: boolean()
  def is_arbitrary_shadow(value) when is_binary(value),
    do: get_is_arbitrary_value(value, &is_label_shadow/1, &is_shadow/1)

  @doc """
  Returns true if the value is an arbitrary variable (e.g., "(variable)").
  """
  @spec is_arbitrary_variable(String.t()) :: boolean()
  def is_arbitrary_variable(value) when is_binary(value) do
    Regex.match?(@arbitrary_variable_regex, value)
  end

  @doc """
  Returns true if the value is an arbitrary variable length (e.g., "(length:var(--size))").
  """
  @spec is_arbitrary_variable_length(String.t()) :: boolean()
  def is_arbitrary_variable_length(value) when is_binary(value) do
    get_is_arbitrary_variable(value, &is_label_length/1)
  end

  @doc """
  Returns true if the value is an arbitrary variable family name (e.g., "(family-name:var(--font))").
  """
  @spec is_arbitrary_variable_family_name(String.t()) :: boolean()
  def is_arbitrary_variable_family_name(value) when is_binary(value) do
    get_is_arbitrary_variable(value, &is_label_family_name/1)
  end

  @doc """
  Returns true if the value is an arbitrary variable position (e.g., "(position:var(--pos))").
  """
  @spec is_arbitrary_variable_position(String.t()) :: boolean()
  def is_arbitrary_variable_position(value) when is_binary(value) do
    get_is_arbitrary_variable(value, &is_label_position/1)
  end

  @doc """
  Returns true if the value is an arbitrary variable size (e.g., "(size:var(--size))").
  """
  @spec is_arbitrary_variable_size(String.t()) :: boolean()
  def is_arbitrary_variable_size(value) when is_binary(value) do
    get_is_arbitrary_variable(value, &is_label_size/1)
  end

  @doc """
  Returns true if the value is an arbitrary variable image (e.g., "(image:var(--img))").
  """
  @spec is_arbitrary_variable_image(String.t()) :: boolean()
  def is_arbitrary_variable_image(value) when is_binary(value) do
    get_is_arbitrary_variable(value, &is_label_image/1)
  end

  @doc """
  Returns true if the value is an arbitrary variable shadow (e.g., "(shadow:var(--shadow))").
  """
  @spec is_arbitrary_variable_shadow(String.t()) :: boolean()
  def is_arbitrary_variable_shadow(value) when is_binary(value) do
    get_is_arbitrary_variable(value, &is_label_shadow/1, true)
  end

  # Helper functions

  # Helper function to check if a value is an arbitrary value with a specific label or value pattern
  @spec get_is_arbitrary_value(String.t(), (String.t() -> boolean()), (String.t() -> boolean())) ::
          boolean()
  defp get_is_arbitrary_value(value, test_label, test_value) when is_binary(value) do
    case Regex.run(@arbitrary_value_regex, value) do
      [_, "", value_part] when not is_nil(value_part) ->
        test_value.(value_part)

      [_, label, _] when not is_nil(label) ->
        test_label.(label)

      _ ->
        false
    end
  end

  # Helper function to check if a value is an arbitrary variable with a specific label
  @spec get_is_arbitrary_variable(String.t(), (String.t() -> boolean()), boolean()) :: boolean()
  defp get_is_arbitrary_variable(value, test_label, should_match_no_label \\ false)
       when is_binary(value) do
    case Regex.run(@arbitrary_variable_regex, value) do
      [_, "", _] ->
        should_match_no_label

      [_, label, _] when not is_nil(label) ->
        test_label.(label)

      _ ->
        false
    end
  end

  # Label validation functions

  # Label validation functions for arbitrary values and variables
  @spec is_label_position(String.t()) :: boolean()
  defp is_label_position(label) when is_binary(label) do
    label == "position" or label == "percentage"
  end

  @spec is_label_image(String.t()) :: boolean()
  defp is_label_image(label) when is_binary(label) do
    label == "image" or label == "url"
  end

  @spec is_label_size(String.t()) :: boolean()
  defp is_label_size(label) when is_binary(label) do
    label == "length" or label == "size" or label == "bg-size"
  end

  @spec is_label_length(String.t()) :: boolean()
  defp is_label_length(label) when is_binary(label) do
    label == "length"
  end

  @spec is_label_number(String.t()) :: boolean()
  defp is_label_number(label) when is_binary(label) do
    label == "number"
  end

  @spec is_label_family_name(String.t()) :: boolean()
  defp is_label_family_name(label) when is_binary(label) do
    label == "family-name"
  end

  @spec is_label_shadow(String.t()) :: boolean()
  defp is_label_shadow(label) when is_binary(label) do
    label == "shadow"
  end
end
