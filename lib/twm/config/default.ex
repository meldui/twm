defmodule Twm.Config.Default do
  @moduledoc """
  Default configuration for Twm.

  This module provides the default configuration for Twm, which includes:
  - Default class groups
  - Conflicting class groups
  - Theme scales
  """

  alias Twm.Config.Theme

  # Theme getters for theme variable namespaces
  # @see https://tailwindcss.com/docs/theme#theme-variable-namespaces
  defp theme_color, do: Theme.from_theme(:color)
  defp theme_font, do: Theme.from_theme(:font)
  defp theme_text, do: Theme.from_theme(:text)
  defp theme_font_weight, do: Theme.from_theme(:"font-weight")
  defp theme_tracking, do: Theme.from_theme(:tracking)
  defp theme_leading, do: Theme.from_theme(:leading)
  defp theme_breakpoint, do: Theme.from_theme(:breakpoint)
  defp theme_container, do: Theme.from_theme(:container)
  defp theme_spacing, do: Theme.from_theme(:spacing)
  defp theme_radius, do: Theme.from_theme(:radius)
  defp theme_shadow, do: Theme.from_theme(:shadow)
  defp theme_inset_shadow, do: Theme.from_theme(:"inset-shadow")
  defp theme_text_shadow, do: Theme.from_theme(:"text-shadow")
  defp theme_drop_shadow, do: Theme.from_theme(:"drop-shadow")
  defp theme_blur, do: Theme.from_theme(:blur)
  defp theme_perspective, do: Theme.from_theme(:perspective)
  defp theme_aspect, do: Theme.from_theme(:aspect)
  defp theme_ease, do: Theme.from_theme(:ease)
  defp theme_animate, do: Theme.from_theme(:animate)

  @doc """
  Returns the default configuration for Twm.

  ## Examples

      iex> config = Twm.Config.Default.get()
      iex> config.cache_size
      500
      iex> "block" in config.class_groups.display
      true

  """
  @spec get() :: map()
  def get do
    %{
      cache_name: Twm.Cache,
      cache_size: 500,
      theme: theme(),
      class_groups: class_groups(),
      conflicting_class_groups: conflicting_class_groups(),
      conflicting_class_group_modifiers: conflicting_class_group_modifiers(),
      order_sensitive_modifiers: order_sensitive_modifiers()
    }
  end

  # Scale helpers
  defp scale_break do
    ["auto", "avoid", "all", "avoid-page", "page", "left", "right", "column"]
  end

  defp scale_position do
    [
      "center",
      "top",
      "bottom",
      "left",
      "right",
      "top-left",
      # Deprecated since Tailwind CSS v4.1.0
      "left-top",
      "top-right",
      # Deprecated since Tailwind CSS v4.1.0
      "right-top",
      "bottom-right",
      # Deprecated since Tailwind CSS v4.1.0
      "right-bottom",
      "bottom-left",
      # Deprecated since Tailwind CSS v4.1.0
      "left-bottom"
    ]
  end

  defp scale_position_with_arbitrary do
    scale_position() ++ [&Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_grid_col_row_start_or_end do
    [&Twm.is_integer/1, "auto", &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_grid_auto_cols_rows do
    ["auto", "min", "max", "fr", &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_align_primary_axis do
    [
      "start",
      "end", 
      "center",
      "between",
      "around",
      "evenly",
      "stretch",
      "baseline",
      "center-safe",
      "end-safe"
    ]
  end

  defp scale_align_secondary_axis do
    ["start", "end", "center", "stretch", "center-safe", "end-safe"]
  end

  defp scale_margin do
    ["auto"] ++ scale_unambiguous_spacing()
  end

  defp scale_sizing do
    [
      &Twm.is_fraction/1,
      "auto",
      "full",
      "dvw",
      "dvh",
      "lvw",
      "lvh",
      "svw",
      "svh",
      "min",
      "max",
      "fit"
    ] ++ scale_unambiguous_spacing()
  end

  defp scale_color do
    [theme_color(), &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_bg_position do
    scale_position() ++ [&Twm.is_arbitrary_variable_position/1, &Twm.is_arbitrary_position/1] ++ [%{position: [&Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]}]
  end

  defp scale_bg_repeat do
    ["no-repeat", %{repeat: ["", "x", "y", "space", "round"]}]
  end

  defp scale_bg_size do
    [
      "auto",
      "cover",
      "contain",
      &Twm.is_arbitrary_variable_size/1,
      &Twm.is_arbitrary_size/1,
      %{size: [&Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]}
    ]
  end

  defp scale_gradient_stop_position do
    [&Twm.is_percent/1, &Twm.is_arbitrary_variable_length/1, &Twm.is_arbitrary_length/1]
  end

  defp scale_radius do
    [
      # Deprecated since Tailwind CSS v4.0.0
      "",
      "none",
      "full",
      theme_radius(),
      &Twm.is_arbitrary_variable/1,
      &Twm.is_arbitrary_value/1
    ]
  end

  defp scale_border_width do
    ["", &Twm.is_number/1, &Twm.is_arbitrary_variable_length/1, &Twm.is_arbitrary_length/1]
  end

  defp scale_line_style do
    ["solid", "dashed", "dotted", "double"]
  end

  defp scale_blend_mode do
    [
      "normal",
      "multiply",
      "screen",
      "overlay",
      "darken",
      "lighten",
      "color-dodge",
      "color-burn",
      "hard-light",
      "soft-light",
      "difference",
      "exclusion",
      "hue",
      "saturation",
      "color",
      "luminosity"
    ]
  end

  defp scale_mask_image_position do
    [&Twm.is_number/1, &Twm.is_percent/1, &Twm.is_arbitrary_variable_position/1, &Twm.is_arbitrary_position/1]
  end

  defp scale_blur do
    [
      # Deprecated since Tailwind CSS v4.0.0
      "",
      "none",
      theme_blur(),
      &Twm.is_arbitrary_variable/1,
      &Twm.is_arbitrary_value/1
    ]
  end

  defp scale_rotate do
    ["none", &Twm.is_number/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_scale do
    ["none", &Twm.is_number/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_skew do
    [&Twm.is_number/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
  end

  defp scale_translate do
    [&Twm.is_fraction/1, "full"] ++ scale_unambiguous_spacing()
  end

  defp scale_overscroll do
    ["auto", "contain", "none"]
  end

  defp scale_overflow do
    ["auto", "hidden", "clip", "visible", "scroll"]
  end

  defp scale_unambiguous_spacing do
    [&Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1, theme_spacing()]
  end

  defp scale_inset do
    [&Twm.is_fraction/1, "full", "auto"] ++ scale_unambiguous_spacing()
  end

  defp scale_grid_template_cols_rows do
    [
      &Twm.is_integer/1,
      "none",
      "subgrid",
      &Twm.is_arbitrary_variable/1,
      &Twm.is_arbitrary_value/1
    ]
  end

  defp scale_grid_col_row_start_and_end do
    [
      "auto",
      %{span: ["full", &Twm.is_integer/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]},
      &Twm.is_integer/1,
      &Twm.is_arbitrary_variable/1,
      &Twm.is_arbitrary_value/1
    ]
  end

  # Configuration components
  defp theme do
    %{
      animate: ["spin", "ping", "pulse", "bounce"],
      aspect: ["video"],
      blur: [&Twm.is_tshirt_size/1],
      breakpoint: [&Twm.is_tshirt_size/1],
      color: [&Twm.is_any/1],
      container: [&Twm.is_tshirt_size/1],
      "drop-shadow": [&Twm.is_tshirt_size/1],
      ease: ["in", "out", "in-out"],
      font: [&Twm.is_any_non_arbitrary/1],
      "font-weight": [
        "thin",
        "extralight", 
        "light",
        "normal",
        "medium",
        "semibold",
        "bold",
        "extrabold",
        "black"
      ],
      "inset-shadow": [&Twm.is_tshirt_size/1],
      leading: ["none", "tight", "snug", "normal", "relaxed", "loose"],
      perspective: ["dramatic", "near", "normal", "midrange", "distant", "none"],
      radius: [&Twm.is_tshirt_size/1],
      shadow: [&Twm.is_tshirt_size/1],
      spacing: ["px", &Twm.is_number/1],
      text: [&Twm.is_tshirt_size/1],
      "text-shadow": [&Twm.is_tshirt_size/1],
      tracking: ["tighter", "tight", "normal", "wide", "wider", "widest"]
    }
  end

  defp class_groups do
    %{
      # Layout
      display: [
        "block",
        "inline-block",
        "inline",
        "flex",
        "inline-flex",
        "table",
        "inline-table",
        "table-caption",
        "table-cell",
        "table-column",
        "table-column-group",
        "table-footer-group",
        "table-header-group",
        "table-row-group",
        "table-row",
        "flow-root",
        "grid",
        "inline-grid",
        "contents",
        "list-item",
        "hidden"
      ],
      position: ["static", "fixed", "absolute", "relative", "sticky"],
      float: [%{float: ["right", "left", "none", "start", "end"]}],
      clear: [%{clear: ["left", "right", "both", "none", "start", "end"]}],
      inset: [%{inset: scale_inset()}],
      "inset-x": [%{"inset-x": scale_inset()}],
      "inset-y": [%{"inset-y": scale_inset()}],
      start: [%{start: scale_inset()}],
      end: [%{end: scale_inset()}],
      top: [%{top: scale_inset()}],
      right: [%{right: scale_inset()}],
      bottom: [%{bottom: scale_inset()}],
      left: [%{left: scale_inset()}],
      visibility: ["visible", "invisible", "collapse"],
      z: [%{z: ["auto", &Twm.is_integer/1, &Twm.is_arbitrary_value/1]}],

      # Overflow
      overflow: [%{overflow: scale_overflow()}],
      "overflow-x": [%{"overflow-x": scale_overflow()}],
      "overflow-y": [%{"overflow-y": scale_overflow()}],
      overscroll: [%{overscroll: scale_overscroll()}],
      "overscroll-x": [%{"overscroll-x": scale_overscroll()}],
      "overscroll-y": [%{"overscroll-y": scale_overscroll()}],

      # Flexbox and Grid
      flex: [%{flex: [&Twm.is_number/1, &Twm.is_fraction/1, "auto", "initial", "none", &Twm.is_arbitrary_value/1]}],
      "flex-direction": [%{flex: ["row", "row-reverse", "col", "col-reverse"]}],
      "flex-wrap": [%{flex: ["nowrap", "wrap", "wrap-reverse"]}],
      grow: [%{grow: ["0", "1", &Twm.is_arbitrary_value/1]}],
      shrink: [%{shrink: ["0", "1", &Twm.is_arbitrary_value/1]}],
      basis: [%{basis: scale_sizing()}],

      # Grid
      "grid-cols": [%{"grid-cols": scale_grid_template_cols_rows()}],
      "col-start-end": [%{col: scale_grid_col_row_start_and_end()}],
      "col-start": [%{"col-start": scale_grid_col_row_start_or_end()}],
      "col-end": [%{"col-end": scale_grid_col_row_start_or_end()}],
      "grid-rows": [%{"grid-rows": scale_grid_template_cols_rows()}],
      "grid-flow": [%{"grid-flow": ["row", "col", "dense", "row-dense", "col-dense"]}],
      "row-start-end": [%{row: scale_grid_col_row_start_and_end()}],
      "row-start": [%{"row-start": scale_grid_col_row_start_or_end()}],
      "row-end": [%{"row-end": scale_grid_col_row_start_or_end()}],
      "auto-cols": [%{"auto-cols": scale_grid_auto_cols_rows()}],
      "auto-rows": [%{"auto-rows": scale_grid_auto_cols_rows()}],

      # Spacing
      gap: [%{gap: scale_unambiguous_spacing()}],
      "gap-x": [%{"gap-x": scale_unambiguous_spacing()}],
      "gap-y": [%{"gap-y": scale_unambiguous_spacing()}],

      # Spacing - using scales instead of explicit class lists
      p: [%{p: scale_unambiguous_spacing()}],
      px: [%{px: scale_unambiguous_spacing()}],
      py: [%{py: scale_unambiguous_spacing()}],
      ps: [%{ps: scale_unambiguous_spacing()}],
      pe: [%{pe: scale_unambiguous_spacing()}],
      pt: [%{pt: scale_unambiguous_spacing()}],
      pr: [%{pr: scale_unambiguous_spacing()}],
      pb: [%{pb: scale_unambiguous_spacing()}],
      pl: [%{pl: scale_unambiguous_spacing()}],

      # Margin
      m: [%{m: scale_margin()}],
      mx: [%{mx: scale_margin()}],
      my: [%{my: scale_margin()}],
      ms: [%{ms: scale_margin()}],
      me: [%{me: scale_margin()}],
      mt: [%{mt: scale_margin()}],
      mr: [%{mr: scale_margin()}],
      mb: [%{mb: scale_margin()}],
      ml: [%{ml: scale_margin()}],

      # Sizing
      w: [%{w: scale_sizing()}],
      h: [%{h: scale_sizing()}],
      size: [%{size: scale_sizing()}],

      # Typography
      "font-size": [%{"font-size": ["xs", "sm", "base", "lg", "xl", &Twm.is_arbitrary_value/1]}],

      # Font Variant Numeric - separated by type to handle conflicts correctly
      "fvn-normal": ["normal-nums"],
      "fvn-ordinal": ["ordinal"],
      "fvn-slashed-zero": ["slashed-zero"],
      "fvn-figure": ["lining-nums", "oldstyle-nums"],
      "fvn-spacing": ["proportional-nums", "tabular-nums"],
      "fvn-fraction": ["diagonal-fractions", "stacked-fractions"]
    }
  end

  defp conflicting_class_groups do
    %{
      overflow: ["overflow-x", "overflow-y"],
      overscroll: ["overscroll-x", "overscroll-y"],
      inset: ["inset-x", "inset-y", "start", "end", "top", "right", "bottom", "left"],
      "inset-x": ["right", "left"],
      "inset-y": ["top", "bottom"],
      flex: ["basis", "grow", "shrink"],
      gap: ["gap-x", "gap-y"],
      p: ["px", "py", "ps", "pe", "pt", "pr", "pb", "pl"],
      px: ["pr", "pl"],
      py: ["pt", "pb"],
      m: ["mx", "my", "ms", "me", "mt", "mr", "mb", "ml"],
      mx: ["mr", "ml"],
      my: ["mt", "mb"],
      size: ["w", "h"],
      "font-size": ["leading"],
      "fvn-normal": [
        "fvn-ordinal",
        "fvn-slashed-zero",
        "fvn-figure",
        "fvn-spacing",
        "fvn-fraction"
      ],
      "fvn-ordinal": ["fvn-normal"],
      "fvn-slashed-zero": ["fvn-normal"],
      "fvn-figure": ["fvn-normal"],
      "fvn-spacing": ["fvn-normal"],
      "fvn-fraction": ["fvn-normal"]
    }
  end

  defp conflicting_class_group_modifiers do
    %{
      # No conflicting class group modifiers yet
    }
  end

  defp order_sensitive_modifiers do
    [
      # Add order sensitive modifiers here
    ]
  end
end