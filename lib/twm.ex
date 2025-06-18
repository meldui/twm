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
  @spec merge(String.t() | [String.t()]) :: String.t()
  def merge(classes) when is_binary(classes) do
    case Cache.get(classes) do
      {:ok, result} ->
        result

      :error ->
        result = do_merge(classes)
        Cache.put(classes, result)
        result
    end
  end

  def merge(classes) when is_list(classes) do
    classes
    |> flatten_and_filter_classes()
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
      ...>   [
      ...>     cache_name: Twm.Cache,
      ...>     cache_size: 20,
      ...>     theme: [],
      ...>     class_groups: [
      ...>       fooKey: [%{fooKey: ["bar", "baz"]}],
      ...>       fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
      ...>       otherKey: ["nother", "group"]
      ...>     ],
      ...>     conflicting_class_groups: [
      ...>       fooKey: ["otherKey"],
      ...>       otherKey: ["fooKey", "fooKey2"]
      ...>     ],
      ...>     conflicting_class_group_modifiers: [],
      ...>     order_sensitive_modifiers: []
      ...>   ]
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

  @doc """
  Extends the default tailwind merge function with the provided configuration options.

  This function creates a custom tailwind merge function by extending the default
  configuration with the provided options.

  ## Examples

      iex> custom_merge = Twm.extend_tailwind_merge(
      ...>   experimental_parse_class_name: fn %{class_name: class_name, parse_class_name: parse_class_name} ->
      ...>     parse_class_name.(String.slice(class_name, 3..-1//1))
      ...>   end
      ...> )
      iex> custom_merge.("barpx-2 foopy-1 lolp-3")
      "p-3"

  """
  @spec extend_tailwind_merge(keyword()) :: (String.t() -> String.t())
  def extend_tailwind_merge(options) when is_list(options) do
    # Create a custom merge function with the extended configuration
    fn classes ->
      # Separate extend options from other options
      {extend_options, other_options} = Keyword.split(options, [:extend])

      # Use proper config extension logic for extend options
      config =
        case extend_options[:extend] do
          nil -> Twm.Config.get_default()
          extend_config -> Twm.Config.extend(extend: extend_config)
        end

      # Merge other options directly (for experimental_parse_class_name, etc.)
      final_config = Keyword.merge(config, other_options)

      # Perform the merge with the custom config
      if is_binary(classes) do
        merge_with_config(classes, final_config)
      else
        classes
        |> List.wrap()
        |> Enum.join(" ")
        |> merge_with_config(config)
      end
    end
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

  # Private helper to merge classes with a specific configuration
  defp merge_with_config(classes, config) when is_binary(classes) do
    if classes == "" do
      ""
    else
      Twm.Merger.merge_classes(classes, config)
    end
  end
end
