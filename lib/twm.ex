defmodule Twm do
  @moduledoc """
  TWM - A Tailwind CSS class merger for Elixir.

  Merges Tailwind CSS classes without style conflicts by intelligently
  handling conflicting utilities.
  """

  alias Twm.Cache
  alias Twm.Config.Create

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
    # Get config from the application environment or use default
    config = Application.get_env(:twm, :config, Twm.Config.get_default())
    
    # Use the proper merger implementation
    Twm.Merger.merge_classes(classes, config)
  end

  @doc """
  Alternative name for `merge/1` function.
  """
  @spec tw_merge(String.t() | [String.t()]) :: String.t()
  def tw_merge(classes), do: merge(classes)

  @doc """
  Creates a custom tailwind merge function with the provided configuration functions.

  This function allows you to create a tailwind merge function with a custom configuration.
  It accepts one or more configuration functions that are applied in sequence.

  ## Examples

      iex> custom_merge = Twm.create_tailwind_merge(fn ->
      ...>   %{
      ...>     cache_name: Twm.Cache,
      ...>     cache_size: 20,
      ...>     theme: %{},
      ...>     class_groups: %{
      ...>       fooKey: [%{fooKey: ["bar", "baz"]}],
      ...>       fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
      ...>       otherKey: ["nother", "group"]
      ...>     },
      ...>     conflicting_class_groups: %{
      ...>       fooKey: ["otherKey"],
      ...>       otherKey: ["fooKey", "fooKey2"]
      ...>     },
      ...>     conflicting_class_group_modifiers: %{},
      ...>     order_sensitive_modifiers: []
      ...>   }
      ...> end)
      iex> custom_merge.("my-modifier:fooKey-bar my-modifier:fooKey-baz")
      "my-modifier:fooKey-baz"
  """
  @spec create_tailwind_merge((-> map()) | [(-> map()) | (map() -> map())]) :: (String.t() ->
                                                                                  String.t())
  def create_tailwind_merge(config_fns) when is_list(config_fns) do
    Create.tailwind_merge(config_fns)
  end

  def create_tailwind_merge(config_fn) when is_function(config_fn, 0) do
    Create.tailwind_merge(config_fn)
  end
end
