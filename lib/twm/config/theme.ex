defmodule Twm.Config.Theme do
  @moduledoc """
  Theme helper functions for Twm.

  This module provides functions for working with themes in Tailwind CSS classes.
  It converts the TypeScript `fromTheme` functions to Elixir.
  """

  @doc """
  Creates a theme getter function for the specified theme key.

  ## Examples

      iex> theme_color = Twm.Config.Theme.from_theme("color")
      iex> is_function(theme_color)
      true

  """
  @spec from_theme(String.t()) :: (map() -> any())
  def from_theme(theme_key) when is_binary(theme_key) do
    fn theme_config ->
      case Map.get(theme_config, String.to_atom(theme_key)) do
        nil -> []
        value -> value
      end
    end
  end

  @doc """
  Returns spacing-related theme values.

  This is a convenience function for the spacing theme.
  """
  @spec spacing(map()) :: list()
  def spacing(theme_config), do: from_theme("spacing").(theme_config)

  @doc """
  Returns color-related theme values.

  This is a convenience function for the color theme.
  """
  @spec color(map()) :: list()
  def color(theme_config), do: from_theme("color").(theme_config)

  @doc """
  Returns font-related theme values.

  This is a convenience function for the font theme.
  """
  @spec font(map()) :: list()
  def font(theme_config), do: from_theme("font").(theme_config)

  @doc """
  Returns radius-related theme values.

  This is a convenience function for the radius theme.
  """
  @spec radius(map()) :: list()
  def radius(theme_config), do: from_theme("radius").(theme_config)

  # Additional theme helper functions can be added here as needed
end
