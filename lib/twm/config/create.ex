defmodule Twm.Config.Create do
  @moduledoc """
  Functions for creating custom tailwind merge configurations.

  This module provides functions to create a custom merge function with specific
  configurations, similar to the `createTailwindMerge` function in the original
  JavaScript library.
  """

  alias Twm.Config
  alias Twm.Merger
  alias Twm.Cache

  @doc """
  Creates a custom tailwind merge function with the provided configuration functions.

  This function allows you to create a tailwind merge function with a custom configuration.
  It accepts one or more configuration functions that are applied in sequence.

  ## Examples

      iex> custom_merge = Twm.Config.Create.tailwind_merge(fn ->
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

      iex> custom_merge = Twm.Config.Create.tailwind_merge([
      ...>   fn ->
      ...>     [
      ...>       cache_name: Twm.Cache,
      ...>       cache_size: 20,
      ...>       theme: [],
      ...>       class_groups: [
      ...>         fooKey: [%{fooKey: ["bar", "baz"]}],
      ...>         fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
      ...>         otherKey: ["nother", "group"]
      ...>       ],
      ...>       conflicting_class_groups: [
      ...>         fooKey: ["otherKey"],
      ...>         otherKey: ["fooKey", "fooKey2"]
      ...>       ],
      ...>       conflicting_class_group_modifiers: [],
      ...>       order_sensitive_modifiers: []
      ...>     ]
      ...>   end,
      ...>   fn config ->
      ...>     config = Keyword.update!(config, :class_groups, fn class_groups ->
      ...>       Keyword.put(class_groups, :helloFromSecondConfig, ["hello-there"])
      ...>     end)
      ...>
      ...>     Keyword.update!(config, :conflicting_class_groups, fn conflicting ->
      ...>       Keyword.update(conflicting, :fooKey, ["helloFromSecondConfig"], fn existing ->
      ...>         existing ++ ["helloFromSecondConfig"]
      ...>       end)
      ...>     end)
      ...>   end
      ...> ])
      iex> custom_merge.("hello-there fooKey-bar")
      "fooKey-bar"
  """
  @spec tailwind_merge((-> map()) | [(-> map()) | (map() -> map())]) :: (String.t()
                                                                         | [String.t()] ->
                                                                           String.t())
  def tailwind_merge(config_fns) when is_list(config_fns) and length(config_fns) > 0 do
    [first_fn | rest_fns] = config_fns
    tailwind_merge(first_fn, rest_fns)
  end

  def tailwind_merge(config_fn) when is_function(config_fn, 0) do
    tailwind_merge(config_fn, [])
  end

  @spec tailwind_merge((-> map()), ([(map() -> map())] | map() -> map())) :: (String.t() ->
                                                                                String.t())
  def tailwind_merge(first_config_fn, rest_config_fns)
      when is_function(first_config_fn, 0) and
             (is_list(rest_config_fns) or is_function(rest_config_fns, 1)) do
    # Convert single function to list if needed
    rest_config_fns_list =
      if is_function(rest_config_fns, 1), do: [rest_config_fns], else: rest_config_fns

    config =
      rest_config_fns_list
      |> Enum.reduce(first_config_fn.(), fn config_fn, acc ->
        config_fn.(acc)
      end)

    {:ok, valid_config} =
      case Config.validate(config) do
        {:ok, valid_config} ->
          {:ok, valid_config}

        {:error, reason} ->
          raise ArgumentError, "Invalid configuration: #{reason}"
      end

    fn classes when is_binary(classes) or is_list(classes) ->
      # Convert list of classes to a single string if needed
      classes_str = if is_list(classes), do: Enum.join(classes, " "), else: classes

      do_merge(classes_str, valid_config)
    end
  end

  # Private function to perform the actual merge with a specific configuration
  defp do_merge(classes, config) when is_binary(classes) do
    # Try to get result from cache first
    case Cache.get(config[:cache_name], classes) do
      {:ok, result} ->
        # Cache hit
        result

      :error ->
        # Cache miss - perform the merge operation with the specific config
        result = Merger.merge_classes(classes, config)

        # Cache the result
        Cache.put(config[:cache_name], classes, result)

        result
    end
  end
end
