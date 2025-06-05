defmodule Twm.Config do
  @moduledoc """
  Configuration management for Twm.

  This module provides functions for getting and extending the configuration
  for the Twm library.
  """

  alias Twm.Config.Default

  @doc """
  Returns the default configuration for Twm.

  ## Examples

      iex> config = Twm.Config.get_default()
      iex> config.cache_size
      500

  """
  @spec get_default() :: map()
  def get_default, do: Default.get()

  @doc """
  Extends the default configuration with custom options.

  ## Options

    * `:cache_size` - The size of the LRU cache
    * `:prefix` - The prefix for Tailwind classes
    * `:override` - Configuration values to override (takes precedence over default values)
    * `:extend` - Configuration values to extend (merges with default values)

  ## Examples

      iex> config = Twm.Config.extend(cache_size: 1000)
      iex> config.cache_size
      1000

      iex> config = Twm.Config.extend(override: %{class_groups: %{display: ["custom-display"]}})
      iex> config.class_groups.display
      ["custom-display"]

      iex> config = Twm.Config.extend(extend: %{class_groups: %{custom_group: ["custom-class"]}})
      iex> config.class_groups.custom_group
      ["custom-class"]

  """
  @spec extend(keyword()) :: map()
  def extend(options \\ []) do
    default_config = get_default()

    # Process static options
    config =
      default_config
      |> maybe_update_option(:cache_size, options[:cache_size])
      |> maybe_update_option(:prefix, options[:prefix])

    # Process override options
    config =
      case Keyword.get(options, :override) do
        nil -> config
        override_values -> override_config(config, override_values)
      end

    # Process extend options
    case Keyword.get(options, :extend) do
      nil -> config
      extend_values -> extend_config(config, extend_values)
    end
  end

  # Helper function to update a config option if a value is provided
  defp maybe_update_option(config, _key, nil), do: config
  defp maybe_update_option(config, key, value), do: Map.put(config, key, value)

  # Override configuration values
  defp override_config(config, override_values) when is_map(override_values) do
    override_values
    |> Enum.reduce(config, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  # Extend configuration values
  defp extend_config(config, extend_values) when is_map(extend_values) do
    extend_values
    |> Enum.reduce(config, fn {key, value}, acc ->
      current_value = Map.get(acc, key)

      extended_value = merge(current_value, value)
      Map.put(acc, key, extended_value)
    end)
  end

  defp merge(current_value, value) when is_map(current_value) and is_map(value) do
    Map.merge(current_value, value, fn _k, v1, v2 ->
      case {is_map(v1), is_map(v2)} do
        {true, true} -> Map.merge(v1, v2)
        _ -> v2
      end
    end)
  end

  defp merge(current_value, value) when is_list(current_value) and is_list(value) do
    current_value ++ value
  end

  defp merge(_current_value, value) do
    value
  end

  @doc """
  Validates a configuration map.

  Checks if all required keys are present and the values have the correct types.

  ## Examples

      iex> Twm.Config.validate(Twm.Config.get_default())
      {:ok, %{...}}

      iex> Twm.Config.validate(%{})
      {:error, "Missing required configuration keys: cache_size, theme, class_groups, conflicting_class_groups"}

  """
  @spec validate(map()) :: {:ok, map()} | {:error, String.t()}
  def validate(config) when is_map(config) do
    required_keys = [:cache_name, :cache_size, :theme, :class_groups, :conflicting_class_groups]

    missing_keys =
      Enum.filter(required_keys, fn key ->
        !Map.has_key?(config, key)
      end)

    if Enum.empty?(missing_keys) do
      {:ok, config}
    else
      {:error, "Missing required configuration keys: #{Enum.join(missing_keys, ", ")}"}
    end
  end
end
