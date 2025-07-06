defmodule Twm do
  @moduledoc """
  TWM - A Tailwind CSS class merger for Elixir.

  Merges Tailwind CSS classes without style conflicts by intelligently
  handling conflicting utilities.
  """

  alias Twm.Cache
  alias Twm.Config

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

  @spec merge(String.t() | [String.t()], Keyword.t() | Config.t() | nil) :: String.t()

  def merge(classes, options \\ [])

  def merge(classes, opts) when is_binary(classes) and is_list(opts) do
    cache_name = Keyword.get(opts, :cache_name, Twm.Cache)

    case Cache.get_or_create(cache_name, classes) do
      {:ok, result} ->
        result

      :error ->
        result = Twm.Merger.merge_classes(classes, Twm.Config.get_default())
        result
    end
  end

  def merge(classes, opts) when is_list(classes) and is_list(opts) do
    classes
    |> flatten_and_filter_classes()
    |> Enum.join(" ")
    |> merge(opts)
  end

  def merge(classes, %Twm.Config{} = config) when is_binary(classes) do
    Twm.Merger.merge_classes(classes, config)
  end

  def merge(classes, %Twm.Config{} = config) when is_list(classes) do
    classes
    |> flatten_and_filter_classes()
    |> Enum.join(" ")
    |> merge(config)
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
