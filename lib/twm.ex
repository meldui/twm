defmodule Twm do
  @moduledoc """
  TWM - A Tailwind CSS class merger for Elixir.

  Merges Tailwind CSS classes without style conflicts by intelligently
  handling conflicting utilities.
  """

  alias Twm.Cache
  alias Twm.Types

  # Re-export validators functions
  alias Twm.Validators

  defdelegate is_any(), to: Validators, as: :any?
  defdelegate is_any(value), to: Validators, as: :any?
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
  @spec merge(String.t() | [String.t()], Types.config()) :: String.t()
  def merge(classes, config \\ nil)

  def merge(classes, nil) do
    case Cache.get_config() do
      {:ok, config} ->
        merge(classes, config)

      {:error, _} ->
        merge(classes, Twm.Config.get_default())
    end
  end

  def merge(classes, config) when is_binary(classes) do
    case Cache.get(classes) do
      {:ok, result} ->
        result

      :error ->
        result = do_merge(classes, config)
        Cache.put(classes, result)
        result
    end
  end

  def merge(classes, config) when is_list(classes) do
    classes
    |> flatten_and_filter_classes()
    |> Enum.join(" ")
    |> merge(config)
  end

  # Private function to perform the actual merge operation
  defp do_merge(classes, config) when is_binary(classes) do
    # Use the proper merger implementation
    Twm.Merger.merge_classes(classes, config)
  end

  # Private helper function to flatten nested arrays and filter out nil/false values
  defp flatten_and_filter_classes(classes) do
    classes
    |> List.flatten()
    |> Enum.filter(fn
      nil -> false
      false -> false
      "" -> false
      class when is_binary(class) -> true
      _ -> false
    end)
  end
end
