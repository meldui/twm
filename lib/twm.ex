defmodule Twm do
  @moduledoc """
  TWM - A Tailwind CSS class merger for Elixir.

  Merges Tailwind CSS classes without style conflicts by intelligently
  handling conflicting utilities.
  """

  alias Twm.Cache

  # Re-export validators functions
  alias Twm.Validators

  defdelegate is_any(), to: Validators, as: :any?
  defdelegate is_any_non_arbitrary(value), to: Validators
  defdelegate is_arbitrary_image(value), to: Validators
  defdelegate is_arbitrary_length(value), to: Validators
  defdelegate is_arbitrary_number(value), to: Validators
  defdelegate is_arbitrary_position(value), to: Validators
  defdelegate is_arbitrary_shadow(value), to: Validators
  defdelegate is_arbitrary_size(value), to: Validators
  defdelegate is_arbitrary_value(value), to: Validators
  defdelegate is_arbitrary_variable(value), to: Validators
  defdelegate is_arbitrary_variable_family_name(value), to: Validators
  defdelegate is_arbitrary_variable_image(value), to: Validators
  defdelegate is_arbitrary_variable_length(value), to: Validators
  defdelegate is_arbitrary_variable_position(value), to: Validators
  defdelegate is_arbitrary_variable_shadow(value), to: Validators
  defdelegate is_arbitrary_variable_size(value), to: Validators
  defdelegate is_fraction(value), to: Validators
  defdelegate is_integer(value), to: Validators, as: :is_integer_value
  defdelegate is_number(value), to: Validators, as: :is_number_value
  defdelegate is_percent(value), to: Validators, as: :percent?
  defdelegate is_tshirt_size(value), to: Validators

  @doc """
  Merges multiple Tailwind CSS classes into a single string, removing conflicting classes.

  This function uses an LRU cache to improve performance for repeated calls with the
  same input classes.

  ## Examples

      iex> Twm.merge("px-2 px-4")
      "px-4"

      iex> Twm.merge("pt-2 pt-4 pb-3")
      "pt-4 pb-3"

  """
  @spec merge(String.t() | [String.t()]) :: String.t()
  def merge(classes) when is_binary(classes) do
    # Try to get result from cache first
    case Cache.get(classes) do
      {:ok, result} ->
        # Cache hit
        result

      :error ->
        # Cache miss - perform the merge operation
        result = do_merge(classes)

        # Cache the result
        Cache.put(classes, result)

        result
    end
  end

  def merge(classes) when is_list(classes) do
    classes
    |> Enum.join(" ")
    |> merge()
  end

  # Private function to perform the actual merge operation
  defp do_merge(classes) when is_binary(classes) do
    # Split the classes by whitespace
    class_list = String.split(classes)

    # Create a map to track the latest occurrence of each class prefix
    # Example: px-2 and px-4 both have "px-" prefix, so we keep the last one
    class_map =
      Enum.reduce(class_list, %{}, fn class, acc ->
        prefix = get_class_prefix(class)
        Map.put(acc, prefix, class)
      end)

    # Convert the map values back to a list, keeping the original order of prefixes
    original_prefixes = Enum.map(class_list, &get_class_prefix/1)
    unique_prefixes_in_order = Enum.uniq(original_prefixes)

    unique_prefixes_in_order
    |> Enum.map_join(" ", fn prefix -> Map.get(class_map, prefix) end)
  end

  # Extract the prefix of a Tailwind class
  # For example, "px-2" -> "px-", "pt-4" -> "pt-"
  defp get_class_prefix(class) do
    case String.split(class, "-", parts: 2) do
      [prefix, _] -> prefix <> "-"
      # No prefix found, use the whole class
      _ -> class
    end
  end

  @doc """
  Alternative name for `merge/1` function.
  """
  @spec tw_merge(String.t() | [String.t()]) :: String.t()
  def tw_merge(classes), do: merge(classes)
end
