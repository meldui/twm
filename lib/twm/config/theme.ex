defmodule Twm.Config.Theme do
  @moduledoc """
  Theme helper functions for Twm.

  This module provides functions for working with themes in Tailwind CSS classes.
  It converts the TypeScript `fromTheme` functions to Elixir.
  """

  defmodule ThemeGetter do
    @moduledoc """
    A struct that identifies a theme key for lookup.

    This replaces the anonymous function approach to eliminate memory pressure
    from closures in the configuration.
    """

    @enforce_keys [:key]
    defstruct [:key, is_theme_getter: true]

    @type t :: %__MODULE__{
            key: String.t() | atom(),
            is_theme_getter: true
          }
  end

  @doc """
  Creates a theme getter function for the specified theme key.

  This is the Elixir equivalent of the TypeScript `fromTheme` function.
  Returns a `ThemeGetter` struct that can be identified as a theme getter
  and called to extract theme values.

  ## Parameters

    * `theme_key` - The theme key to extract from theme configuration (string or atom)

  ## Returns

  A `ThemeGetter` struct containing:
    * `:key` - The theme key
    * `:getter_fn` - Function that extracts values from theme config
    * `:is_theme_getter` - Always `true` to mark this as a theme getter

  ## Examples

      iex> theme_spacing = Twm.Config.Theme.from_theme("spacing")
      iex> theme_spacing.is_theme_getter
      true

      iex> theme_color = Twm.Config.Theme.from_theme(:color)
      iex> theme_color.key
      :color

      iex> theme_config = %{spacing: ["1", "2", "4", "8"]}
      iex> theme_spacing = Twm.Config.Theme.from_theme("spacing")
      iex> Twm.Config.Theme.call_theme_getter(theme_spacing, theme_config)
      ["1", "2", "4", "8"]

      iex> theme_config = %{color: ["red", "blue"]}
      iex> theme_missing = Twm.Config.Theme.from_theme("missing")
      iex> Twm.Config.Theme.call_theme_getter(theme_missing, theme_config)
      []

  """
  @spec from_theme(String.t() | atom()) :: ThemeGetter.t()
  def from_theme(theme_key) when is_binary(theme_key) do
    from_theme(String.to_atom(theme_key))
  end

  def from_theme(theme_key) when is_atom(theme_key) do
    %ThemeGetter{
      key: theme_key,
      is_theme_getter: true
    }
  end

  @doc """
  Calls a theme getter function with the provided theme configuration.

  This function handles both `ThemeGetter` structs and regular functions
  for backwards compatibility.

  ## Parameters

    * `theme_getter` - A `ThemeGetter` struct or regular function
    * `theme_config` - The theme configuration map

  ## Examples

      iex> theme_spacing = Twm.Config.Theme.from_theme(:spacing)
      iex> config = %{spacing: ["1", "2", "4"]}
      iex> Twm.Config.Theme.call_theme_getter(theme_spacing, config)
      ["1", "2", "4"]

  """
  @spec call_theme_getter(ThemeGetter.t() | function(), map()) :: list()
  def call_theme_getter(%ThemeGetter{key: theme_key}, theme_config) do
    case theme_config do
      nil ->
        []

      config when is_map(config) ->
        case Map.get(config, theme_key) do
          nil -> []
          value when is_list(value) -> value
          value when is_map(value) -> Map.keys(value)
          value -> [value]
        end

      config when is_list(config) ->
        case Keyword.get(config, theme_key) do
          nil -> []
          value when is_list(value) -> value
          value when is_map(value) -> Map.keys(value)
          value -> [value]
        end

      _ ->
        []
    end
  end

  def call_theme_getter(func, theme_config) when is_function(func, 1) do
    # Handle regular functions for backwards compatibility
    func.(theme_config)
  end

  @doc """
  Checks if a value is a theme getter.

  ## Examples

      iex> theme_spacing = Twm.Config.Theme.from_theme(:spacing)
      iex> Twm.Config.Theme.theme_getter?(theme_spacing)
      true

      iex> regular_func = fn x -> x end
      iex> Twm.Config.Theme.theme_getter?(regular_func)
      false

  """
  @spec theme_getter?(any()) :: boolean()
  def theme_getter?(%ThemeGetter{is_theme_getter: true}), do: true
  def theme_getter?(_), do: false

  # Convenience functions for common theme keys
  # These maintain backwards compatibility with the existing API

  @doc """
  Returns spacing-related theme values.

  This is a convenience function for the spacing theme.
  """
  @spec spacing(map()) :: list()
  def spacing(theme_config), do: call_theme_getter(from_theme(:spacing), theme_config)

  @doc """
  Returns color-related theme values.

  This is a convenience function for the color theme.
  """
  @spec color(map()) :: list()
  def color(theme_config), do: call_theme_getter(from_theme(:color), theme_config)

  @doc """
  Returns font-related theme values.

  This is a convenience function for the font theme.
  """
  @spec font(map()) :: list()
  def font(theme_config), do: call_theme_getter(from_theme(:font), theme_config)

  @doc """
  Returns radius-related theme values.

  This is a convenience function for the radius theme.
  """
  @spec radius(map()) :: list()
  def radius(theme_config), do: call_theme_getter(from_theme(:radius), theme_config)

  @doc """
  Returns shadow-related theme values.

  This is a convenience function for the shadow theme.
  """
  @spec shadow(map()) :: list()
  def shadow(theme_config), do: call_theme_getter(from_theme(:shadow), theme_config)

  @doc """
  Returns text-related theme values.

  This is a convenience function for the text theme.
  """
  @spec text(map()) :: list()
  def text(theme_config), do: call_theme_getter(from_theme(:text), theme_config)

  @doc """
  Returns font-weight-related theme values.

  This is a convenience function for the font-weight theme.
  """
  @spec font_weight(map()) :: list()
  def font_weight(theme_config), do: call_theme_getter(from_theme(:"font-weight"), theme_config)

  @doc """
  Returns tracking-related theme values.

  This is a convenience function for the tracking theme.
  """
  @spec tracking(map()) :: list()
  def tracking(theme_config), do: call_theme_getter(from_theme(:tracking), theme_config)

  @doc """
  Returns leading-related theme values.

  This is a convenience function for the leading theme.
  """
  @spec leading(map()) :: list()
  def leading(theme_config), do: call_theme_getter(from_theme(:leading), theme_config)

  @doc """
  Returns breakpoint-related theme values.

  This is a convenience function for the breakpoint theme.
  """
  @spec breakpoint(map()) :: list()
  def breakpoint(theme_config), do: call_theme_getter(from_theme(:breakpoint), theme_config)

  @doc """
  Returns container-related theme values.

  This is a convenience function for the container theme.
  """
  @spec container(map()) :: list()
  def container(theme_config), do: call_theme_getter(from_theme(:container), theme_config)

  @doc """
  Returns blur-related theme values.

  This is a convenience function for the blur theme.
  """
  @spec blur(map()) :: list()
  def blur(theme_config), do: call_theme_getter(from_theme(:blur), theme_config)

  @doc """
  Returns drop-shadow-related theme values.

  This is a convenience function for the drop-shadow theme.
  """
  @spec drop_shadow(map()) :: list()
  def drop_shadow(theme_config), do: call_theme_getter(from_theme(:"drop-shadow"), theme_config)

  @doc """
  Returns inset-shadow-related theme values.

  This is a convenience function for the inset-shadow theme.
  """
  @spec inset_shadow(map()) :: list()
  def inset_shadow(theme_config), do: call_theme_getter(from_theme(:"inset-shadow"), theme_config)

  @doc """
  Returns text-shadow-related theme values.

  This is a convenience function for the text-shadow theme.
  """
  @spec text_shadow(map()) :: list()
  def text_shadow(theme_config), do: call_theme_getter(from_theme(:"text-shadow"), theme_config)

  @doc """
  Returns perspective-related theme values.

  This is a convenience function for the perspective theme.
  """
  @spec perspective(map()) :: list()
  def perspective(theme_config), do: call_theme_getter(from_theme(:perspective), theme_config)

  @doc """
  Returns aspect-related theme values.

  This is a convenience function for the aspect theme.
  """
  @spec aspect(map()) :: list()
  def aspect(theme_config), do: call_theme_getter(from_theme(:aspect), theme_config)

  @doc """
  Returns ease-related theme values.

  This is a convenience function for the ease theme.
  """
  @spec ease(map()) :: list()
  def ease(theme_config), do: call_theme_getter(from_theme(:ease), theme_config)

  @doc """
  Returns animate-related theme values.

  This is a convenience function for the animate theme.
  """
  @spec animate(map()) :: list()
  def animate(theme_config), do: call_theme_getter(from_theme(:animate), theme_config)
end
