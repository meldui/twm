defmodule Twm.Config do
  @moduledoc """
  Configuration management for Twm.

  This module provides functions for getting and extending the configuration
  for the Twm library.
  """

  alias Twm.Types
  alias Twm.Config.Default

  @typedoc """
  Configuration for the Twm library.

  * `:cache_name` - Name of the LRU cache (if enabled)
  * `:prefix` - Optional prefix for Tailwind classes
  * `:theme` - Theme configuration
  * `:class_groups` - Class group definitions
  * `:conflicting_class_groups` - Groups of class names that conflict with each other
  * `:cache_size` - Size of the LRU cache (if enabled)
  * `:experimental_parse_class_name` - Optional experimental class name parser function
  """
  defstruct [
    :cache_name,
    :cache_size,
    :prefix,
    :theme,
    :class_groups,
    :conflicting_class_groups,
    :conflicting_class_group_modifiers,
    :order_sensitive_modifiers,
    :experimental_parse_class_name
  ]

  @type t :: %__MODULE__{
          cache_name: String.t() | atom() | nil,
          cache_size: non_neg_integer(),
          prefix: String.t() | nil,
          theme: keyword(),
          class_groups: keyword(),
          conflicting_class_groups: keyword(),
          experimental_parse_class_name: (keyword() -> Types.parsed_class_name())
        }

  @doc """
  Returns the default configuration for Twm.

  ## Examples

      iex> config = Twm.Config.get_default()
      iex> config[:cache_size]
      500

  """
  @spec get_default() :: __MODULE__.t()
  def get_default, do: Default.get()

  @spec new(keyword()) :: __MODULE__.t()
  def new(config) do
    case config |> validate() do
      {:ok, config} -> config
      {:error, reason} -> raise("Invalid configuration passed. #{reason}")
    end
  end

  @doc """
  Extends the default configuration with custom options.

  ## Options

    * `:cache_size` - The size of the LRU cache
    * `:prefix` - The prefix for Tailwind classes
    * `:override` - Configuration values to override (takes precedence over default values)
    * `:extend` - Configuration values to extend (merges with default values)

  ## Examples

      iex> config = Twm.Config.extend(cache_size: 1000)
      iex> config[:cache_size]
      1000

      iex> config = Twm.Config.extend(override: [class_groups: [display: ["custom-display"]]])
      iex> config[:class_groups][:display]
      ["custom-display"]

      iex> config = Twm.Config.extend(extend: [class_groups: [custom_group: ["custom-class"]]])
      iex> config[:class_groups][:custom_group]
      ["custom-class"]

  """
  @spec extend(keyword()) :: __MODULE__.t()
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

  @spec extend(__MODULE__.t(), fun()) :: __MODULE__.t()
  def extend(%__MODULE__{} = config, extend_fn) do
    extend_fn.(config)
  end

  # Helper function to update a config option if a value is provided
  defp maybe_update_option(config, _key, nil), do: config
  defp maybe_update_option(config, key, value), do: Map.put(config, key, value)

  # Override configuration values
  defp override_config(config, override_values) when is_list(override_values) do
    override_values
    |> Enum.reduce(config, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  # Extend configuration values
  defp extend_config(config, extend_values) when is_list(extend_values) do
    extend_values
    |> Enum.reduce(config, fn {key, value}, acc ->
      current_value = Map.get(acc, key)

      extended_value = merge(current_value, value)
      Map.put(acc, key, extended_value)
    end)
  end

  defp merge(current_value, value) when is_list(current_value) and is_list(value) do
    # Check if both are keyword lists (have atom keys)
    if Keyword.keyword?(current_value) and Keyword.keyword?(value) do
      Keyword.merge(current_value, value, fn _k, v1, v2 ->
        case {is_list(v1), is_list(v2)} do
          {true, true} -> merge(v1, v2)
          _ -> v2
        end
      end)
    else
      # For regular lists, concatenate
      current_value ++ value
    end
  end

  defp merge(_current_value, value) do
    value
  end

  @doc """
  Validates a configuration keyword list.

  Checks if all required keys are present and the values have the correct types.

  ## Examples

      iex> Twm.Config.validate(Twm.Config.get_default())
      {:ok, [...]}

      iex> Twm.Config.validate([])
      {:error, "Missing required configuration keys: cache_size, theme, class_groups, conflicting_class_groups"}

  """
  def validate(%Twm.Config{} = config) do
    validate(Map.to_list(config))
  end

  @spec validate(keyword()) :: {:ok, keyword()} | {:error, String.t()}
  def validate(config) when is_list(config) do
    # required_keys = [:cache_size, :theme, :class_groups, :conflicting_class_groups]
    required_keys = []

    missing_keys =
      Enum.filter(required_keys, fn key ->
        !Keyword.has_key?(config, key)
      end)

    if Enum.empty?(missing_keys) do
      {:ok,
       %Twm.Config{
         cache_name: Keyword.get(config, :cache_name, Twm.Cache),
         cache_size: Keyword.get(config, :cache_size, 10000),
         theme: Keyword.get(config, :theme, []),
         class_groups: Keyword.get(config, :class_groups, []),
         conflicting_class_groups: Keyword.get(config, :conflicting_class_groups, []),
         conflicting_class_group_modifiers:
           Keyword.get(config, :conflicting_class_group_modifiers, []),
         order_sensitive_modifiers: Keyword.get(config, :order_sensitive_modifiers, []),
         experimental_parse_class_name: Keyword.get(config, :experimental_parse_class_name, nil),
         prefix: Keyword.get(config, :prefix, nil)
       }}
    else
      {:error, "Missing required configuration keys: #{Enum.join(missing_keys, ", ")}"}
    end
  end
end
