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
  @spec get() :: Twm.Config.t()
  def get do
    %Twm.Config{
      cache_name: Twm.Cache,
      cache_size: 10000,
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

  defp scale_overflow do
    ["auto", "hidden", "clip", "visible", "scroll"]
  end

  defp scale_overscroll do
    ["auto", "contain", "none"]
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
      [
        span: ["full", &Twm.is_integer/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
      ],
      &Twm.is_integer/1,
      &Twm.is_arbitrary_variable/1,
      &Twm.is_arbitrary_value/1
    ]
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
    scale_position() ++
      [&Twm.is_arbitrary_variable_position/1, &Twm.is_arbitrary_position/1] ++
      [[position: [&Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]]
  end

  defp scale_bg_repeat do
    ["no-repeat", [repeat: ["", "x", "y", "space", "round"]]]
  end

  defp scale_bg_size do
    [
      "auto",
      "cover",
      "contain",
      &Twm.is_arbitrary_variable_size/1,
      &Twm.is_arbitrary_size/1,
      [size: [&Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
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
      "luminosity",
      "plus-darker",
      "plus-lighter"
    ]
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

  # Configuration components
  defp theme do
    [
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
    ]
  end

  defp class_groups do
    [
      # Layout
      aspect: [
        [
          aspect: [
            "auto",
            "square",
            &Twm.is_fraction/1,
            &Twm.is_arbitrary_value/1,
            &Twm.is_arbitrary_variable/1,
            theme_aspect()
          ]
        ]
      ],
      container: ["container"],
      columns: [
        [
          columns: [
            &Twm.is_number/1,
            &Twm.is_arbitrary_value/1,
            &Twm.is_arbitrary_variable/1,
            theme_container()
          ]
        ]
      ],
      "break-after": [["break-after": scale_break()]],
      "break-before": [["break-before": scale_break()]],
      "break-inside": [["break-inside": ["auto", "avoid", "avoid-page", "avoid-column"]]],
      "box-decoration": [["box-decoration": ["slice", "clone"]]],
      box: [[box: ["border", "content"]]],
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
      sr: ["sr-only", "not-sr-only"],
      float: [[float: ["right", "left", "none", "start", "end"]]],
      clear: [[clear: ["left", "right", "both", "none", "start", "end"]]],
      isolation: ["isolate", "isolation-auto"],
      "object-fit": [[object: ["contain", "cover", "fill", "none", "scale-down"]]],
      "object-position": [[object: scale_position_with_arbitrary()]],
      overflow: [[overflow: scale_overflow()]],
      "overflow-x": [["overflow-x": scale_overflow()]],
      "overflow-y": [["overflow-y": scale_overflow()]],
      overscroll: [[overscroll: scale_overscroll()]],
      "overscroll-x": [["overscroll-x": scale_overscroll()]],
      "overscroll-y": [["overscroll-y": scale_overscroll()]],
      position: ["static", "fixed", "absolute", "relative", "sticky"],
      inset: [[inset: scale_inset()]],
      "inset-x": [["inset-x": scale_inset()]],
      "inset-y": [["inset-y": scale_inset()]],
      start: [[start: scale_inset()]],
      end: [[end: scale_inset()]],
      top: [[top: scale_inset()]],
      right: [[right: scale_inset()]],
      bottom: [[bottom: scale_inset()]],
      left: [[left: scale_inset()]],
      visibility: ["visible", "invisible", "collapse"],
      z: [
        [z: [&Twm.is_integer/1, "auto", &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
      ],

      # Flexbox and Grid
      basis: [
        [
          basis:
            [
              &Twm.is_fraction/1,
              "full",
              "auto",
              theme_container()
            ] ++ scale_unambiguous_spacing()
        ]
      ],
      "flex-direction": [[flex: ["row", "row-reverse", "col", "col-reverse"]]],
      "flex-wrap": [[flex: ["nowrap", "wrap", "wrap-reverse"]]],
      flex: [
        [
          flex: [
            &Twm.is_number/1,
            &Twm.is_fraction/1,
            "auto",
            "initial",
            "none",
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      grow: [
        [grow: ["", &Twm.is_number/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
      ],
      shrink: [
        [shrink: ["", &Twm.is_number/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
      ],
      order: [
        [
          order: [
            &Twm.is_integer/1,
            "first",
            "last",
            "none",
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "grid-cols": [["grid-cols": scale_grid_template_cols_rows()]],
      "col-start-end": [[col: scale_grid_col_row_start_and_end()]],
      "col-start": [["col-start": scale_grid_col_row_start_or_end()]],
      "col-end": [["col-end": scale_grid_col_row_start_or_end()]],
      "grid-rows": [["grid-rows": scale_grid_template_cols_rows()]],
      "row-start-end": [[row: scale_grid_col_row_start_and_end()]],
      "row-start": [["row-start": scale_grid_col_row_start_or_end()]],
      "row-end": [["row-end": scale_grid_col_row_start_or_end()]],
      "grid-flow": [["grid-flow": ["row", "col", "dense", "row-dense", "col-dense"]]],
      "auto-cols": [["auto-cols": scale_grid_auto_cols_rows()]],
      "auto-rows": [["auto-rows": scale_grid_auto_cols_rows()]],
      gap: [[gap: scale_unambiguous_spacing()]],
      "gap-x": [["gap-x": scale_unambiguous_spacing()]],
      "gap-y": [["gap-y": scale_unambiguous_spacing()]],
      "justify-content": [[justify: scale_align_primary_axis() ++ ["normal"]]],
      "justify-items": [["justify-items": scale_align_secondary_axis() ++ ["normal"]]],
      "justify-self": [["justify-self": ["auto"] ++ scale_align_secondary_axis()]],
      "align-content": [[content: ["normal"] ++ scale_align_primary_axis()]],
      "align-items": [[items: scale_align_secondary_axis() ++ [[baseline: ["", "last"]]]]],
      "align-self": [
        [self: ["auto"] ++ scale_align_secondary_axis() ++ [[baseline: ["", "last"]]]]
      ],
      "place-content": [["place-content": scale_align_primary_axis()]],
      "place-items": [["place-items": scale_align_secondary_axis() ++ ["baseline"]]],
      "place-self": [["place-self": ["auto"] ++ scale_align_secondary_axis()]],

      # Spacing
      p: [[p: scale_unambiguous_spacing()]],
      px: [[px: scale_unambiguous_spacing()]],
      py: [[py: scale_unambiguous_spacing()]],
      ps: [[ps: scale_unambiguous_spacing()]],
      pe: [[pe: scale_unambiguous_spacing()]],
      pt: [[pt: scale_unambiguous_spacing()]],
      pr: [[pr: scale_unambiguous_spacing()]],
      pb: [[pb: scale_unambiguous_spacing()]],
      pl: [[pl: scale_unambiguous_spacing()]],
      m: [[m: scale_margin()]],
      mx: [[mx: scale_margin()]],
      my: [[my: scale_margin()]],
      ms: [[ms: scale_margin()]],
      me: [[me: scale_margin()]],
      mt: [[mt: scale_margin()]],
      mr: [[mr: scale_margin()]],
      mb: [[mb: scale_margin()]],
      ml: [[ml: scale_margin()]],
      "space-x": [["space-x": scale_unambiguous_spacing()]],
      "space-x-reverse": ["space-x-reverse"],
      "space-y": [["space-y": scale_unambiguous_spacing()]],
      "space-y-reverse": ["space-y-reverse"],

      # Sizing
      size: [[size: scale_sizing()]],
      w: [[w: [theme_container(), "screen"] ++ scale_sizing()]],
      "min-w": [
        [
          "min-w":
            [
              theme_container(),
              "screen",
              "none"
            ] ++ scale_sizing()
        ]
      ],
      "max-w": [
        [
          "max-w":
            [
              theme_container(),
              "screen",
              "none",
              "prose",
              [screen: [theme_breakpoint()]]
            ] ++ scale_sizing()
        ]
      ],
      h: [[h: ["screen", "lh"] ++ scale_sizing()]],
      "min-h": [["min-h": ["screen", "lh", "none"] ++ scale_sizing()]],
      "max-h": [["max-h": ["screen", "lh"] ++ scale_sizing()]],

      # Typography
      "font-size": [
        [
          text: [
            "base",
            theme_text(),
            &Twm.is_arbitrary_variable_length/1,
            &Twm.is_arbitrary_length/1
          ]
        ]
      ],
      "font-smoothing": ["antialiased", "subpixel-antialiased"],
      "font-style": ["italic", "not-italic"],
      "font-weight": [
        [font: [theme_font_weight(), &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_number/1]]
      ],
      "font-stretch": [
        [
          "font-stretch": [
            "ultra-condensed",
            "extra-condensed",
            "condensed",
            "semi-condensed",
            "normal",
            "semi-expanded",
            "expanded",
            "extra-expanded",
            "ultra-expanded",
            &Twm.is_percent/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "font-family": [
        [
          font: [
            &Twm.is_arbitrary_variable_family_name/1,
            &Twm.is_arbitrary_value/1,
            theme_font()
          ]
        ]
      ],
      "fvn-normal": ["normal-nums"],
      "fvn-ordinal": ["ordinal"],
      "fvn-slashed-zero": ["slashed-zero"],
      "fvn-figure": ["lining-nums", "oldstyle-nums"],
      "fvn-spacing": ["proportional-nums", "tabular-nums"],
      "fvn-fraction": ["diagonal-fractions", "stacked-fractions"],
      tracking: [
        [tracking: [theme_tracking(), &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
      ],
      "line-clamp": [
        [
          "line-clamp": [
            &Twm.is_number/1,
            "none",
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_number/1
          ]
        ]
      ],
      leading: [
        [
          leading:
            [
              theme_leading()
            ] ++ scale_unambiguous_spacing()
        ]
      ],
      "list-image": [
        ["list-image": ["none", &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
      ],
      "list-style-position": [[list: ["inside", "outside"]]],
      "list-style-type": [
        [
          list: [
            "disc",
            "decimal",
            "none",
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "text-alignment": [[text: ["left", "center", "right", "justify", "start", "end"]]],
      "placeholder-color": [[placeholder: scale_color()]],
      "text-color": [[text: scale_color()]],
      "text-decoration": ["underline", "overline", "line-through", "no-underline"],
      "text-decoration-style": [[decoration: scale_line_style() ++ ["wavy"]]],
      "text-decoration-thickness": [
        [
          decoration: [
            &Twm.is_number/1,
            "from-font",
            "auto",
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_length/1
          ]
        ]
      ],
      "text-decoration-color": [[decoration: scale_color()]],
      "underline-offset": [
        [
          "underline-offset": [
            &Twm.is_number/1,
            "auto",
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "text-transform": ["uppercase", "lowercase", "capitalize", "normal-case"],
      "text-overflow": ["truncate", "text-ellipsis", "text-clip"],
      "text-wrap": [[text: ["wrap", "nowrap", "balance", "pretty"]]],
      indent: [[indent: scale_unambiguous_spacing()]],
      "vertical-align": [
        [
          align: [
            "baseline",
            "top",
            "middle",
            "bottom",
            "text-top",
            "text-bottom",
            "sub",
            "super",
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      whitespace: [
        [whitespace: ["normal", "nowrap", "pre", "pre-line", "pre-wrap", "break-spaces"]]
      ],
      break: [[break: ["normal", "words", "all", "keep"]]],
      wrap: [[wrap: ["break-word", "anywhere", "normal"]]],
      hyphens: [[hyphens: ["none", "manual", "auto"]]],
      content: [[content: ["none", &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]],

      # Backgrounds
      "bg-attachment": [[bg: ["fixed", "local", "scroll"]]],
      "bg-clip": [["bg-clip": ["border", "padding", "content", "text"]]],
      "bg-origin": [["bg-origin": ["border", "padding", "content"]]],
      "bg-position": [[bg: scale_bg_position()]],
      "bg-repeat": [[bg: scale_bg_repeat()]],
      "bg-size": [[bg: scale_bg_size()]],
      "bg-image": [
        [
          bg: [
            "none",
            [
              linear: [
                [to: ["t", "tr", "r", "br", "b", "bl", "l", "tl"]],
                &Twm.is_integer/1,
                &Twm.is_arbitrary_variable/1,
                &Twm.is_arbitrary_value/1
              ],
              radial: ["", &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1],
              conic: [&Twm.is_integer/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]
            ],
            &Twm.is_arbitrary_variable_image/1,
            &Twm.is_arbitrary_image/1
          ]
        ]
      ],
      "bg-color": [[bg: scale_color()]],
      "gradient-from-pos": [[from: scale_gradient_stop_position()]],
      "gradient-via-pos": [[via: scale_gradient_stop_position()]],
      "gradient-to-pos": [[to: scale_gradient_stop_position()]],
      "gradient-from": [[from: scale_color()]],
      "gradient-via": [[via: scale_color()]],
      "gradient-to": [[to: scale_color()]],

      # Borders
      rounded: [[rounded: scale_radius()]],
      "rounded-s": [["rounded-s": scale_radius()]],
      "rounded-e": [["rounded-e": scale_radius()]],
      "rounded-t": [["rounded-t": scale_radius()]],
      "rounded-r": [["rounded-r": scale_radius()]],
      "rounded-b": [["rounded-b": scale_radius()]],
      "rounded-l": [["rounded-l": scale_radius()]],
      "rounded-ss": [["rounded-ss": scale_radius()]],
      "rounded-se": [["rounded-se": scale_radius()]],
      "rounded-ee": [["rounded-ee": scale_radius()]],
      "rounded-es": [["rounded-es": scale_radius()]],
      "rounded-tl": [["rounded-tl": scale_radius()]],
      "rounded-tr": [["rounded-tr": scale_radius()]],
      "rounded-br": [["rounded-br": scale_radius()]],
      "rounded-bl": [["rounded-bl": scale_radius()]],
      "border-spacing": [["border-spacing": scale_unambiguous_spacing()]],
      "border-spacing-x": [["border-spacing-x": scale_unambiguous_spacing()]],
      "border-spacing-y": [["border-spacing-y": scale_unambiguous_spacing()]],
      "border-w": [[border: scale_border_width()]],
      "border-w-x": [["border-x": scale_border_width()]],
      "border-w-y": [["border-y": scale_border_width()]],
      "border-w-s": [["border-s": scale_border_width()]],
      "border-w-e": [["border-e": scale_border_width()]],
      "border-w-t": [["border-t": scale_border_width()]],
      "border-w-r": [["border-r": scale_border_width()]],
      "border-w-b": [["border-b": scale_border_width()]],
      "border-w-l": [["border-l": scale_border_width()]],
      "border-color": [[border: scale_color()]],
      "border-color-x": [["border-x": scale_color()]],
      "border-color-y": [["border-y": scale_color()]],
      "border-color-s": [["border-s": scale_color()]],
      "border-color-e": [["border-e": scale_color()]],
      "border-color-t": [["border-t": scale_color()]],
      "border-color-r": [["border-r": scale_color()]],
      "border-color-b": [["border-b": scale_color()]],
      "border-color-l": [["border-l": scale_color()]],
      "border-style": [[border: scale_line_style()]],
      "border-style-x": [["border-x": scale_line_style()]],
      "border-style-y": [["border-y": scale_line_style()]],
      "border-style-s": [["border-s": scale_line_style()]],
      "border-style-e": [["border-e": scale_line_style()]],
      "border-style-t": [["border-t": scale_line_style()]],
      "border-style-r": [["border-r": scale_line_style()]],
      "border-style-b": [["border-b": scale_line_style()]],
      "border-style-l": [["border-l": scale_line_style()]],
      "border-opacity": [["border-opacity": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],

      # Divide
      "divide-x": [["divide-x": scale_border_width()]],
      "divide-y": [["divide-y": scale_border_width()]],
      "divide-x-reverse": ["divide-x-reverse"],
      "divide-y-reverse": ["divide-y-reverse"],
      "divide-style": [[divide: scale_line_style()]],
      "divide-color": [[divide: scale_color()]],
      "divide-opacity": [["divide-opacity": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],

      # Ring
      ring: [[ring: ["", "0", "1", "2", "4", "8", &Twm.is_arbitrary_value/1]]],
      "ring-inset": ["ring-inset"],
      "ring-color": [[ring: scale_color()]],
      "ring-opacity": [["ring-opacity": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      "ring-offset": [["ring-offset": scale_unambiguous_spacing()]],
      "ring-offset-color": [["ring-offset": scale_color()]],

      # Effects
      shadow: [
        [
          shadow: [
            "",
            "3xs",
            "sm",
            "md",
            "lg",
            "xl",
            "2xl",
            "inner",
            "none",
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "shadow-color": [[shadow: scale_color()]],
      opacity: [[opacity: [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      "mix-blend": [["mix-blend": scale_blend_mode()]],
      "bg-blend": [["bg-blend": scale_blend_mode()]],

      # Filters
      filter: [[filter: ["", "none", &Twm.is_arbitrary_value/1]]],
      blur: [[blur: scale_blur()]],
      brightness: [[brightness: [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      contrast: [[contrast: [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      "drop-shadow": [
        ["drop-shadow": ["", "sm", "md", "lg", "xl", "2xl", "none", &Twm.is_arbitrary_shadow/1]]
      ],
      "drop-shadow-color": [
        ["drop-shadow": scale_color()]
      ],
      grayscale: [[grayscale: ["", "0", &Twm.is_arbitrary_value/1]]],
      "hue-rotate": [["hue-rotate": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      invert: [[invert: ["", "0", &Twm.is_arbitrary_value/1]]],
      saturate: [[saturate: [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      sepia: [[sepia: ["", "0", &Twm.is_arbitrary_value/1]]],
      "backdrop-filter": [["backdrop-filter": ["", "none", &Twm.is_arbitrary_value/1]]],
      "backdrop-blur": [["backdrop-blur": scale_blur()]],
      "backdrop-brightness": [
        ["backdrop-brightness": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "backdrop-contrast": [["backdrop-contrast": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      "backdrop-grayscale": [["backdrop-grayscale": ["", "0", &Twm.is_arbitrary_value/1]]],
      "backdrop-hue-rotate": [
        ["backdrop-hue-rotate": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "backdrop-invert": [["backdrop-invert": ["", "0", &Twm.is_arbitrary_value/1]]],
      "backdrop-opacity": [["backdrop-opacity": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      "backdrop-saturate": [["backdrop-saturate": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]],
      "backdrop-sepia": [["backdrop-sepia": ["", "0", &Twm.is_arbitrary_value/1]]],

      # Tables
      "border-collapse": [[border: ["collapse", "separate"]]],
      "table-layout": [[table: ["auto", "fixed"]]],
      "caption-side": [[caption: ["top", "bottom"]]],

      # Transitions and Animation
      "transition-property": [
        [
          transition: [
            "none",
            "all",
            "",
            "colors",
            "opacity",
            "shadow",
            "transform",
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "transition-duration": [
        [duration: [&Twm.is_number/1, "initial", &Twm.is_arbitrary_value/1]]
      ],
      "transition-timing-function": [
        [
          ease: [
            "linear",
            "initial",
            theme_ease(),
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "transition-delay": [
        [delay: [&Twm.is_number/1, &Twm.is_arbitrary_variable/1, &Twm.is_arbitrary_value/1]]
      ],
      animate: [
        [
          animate: [
            "none",
            theme_animate(),
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],

      # Transforms
      backface: [[backface: ["hidden", "visible"]]],
      perspective: [
        [
          perspective: [
            theme_perspective(),
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "perspective-origin": [["perspective-origin": scale_position_with_arbitrary()]],
      rotate: [[rotate: scale_rotate()]],
      "rotate-x": [["rotate-x": scale_rotate()]],
      "rotate-y": [["rotate-y": scale_rotate()]],
      "rotate-z": [["rotate-z": scale_rotate()]],
      scale: [[scale: scale_scale()]],
      "scale-x": [["scale-x": scale_scale()]],
      "scale-y": [["scale-y": scale_scale()]],
      "scale-z": [["scale-z": scale_scale()]],
      "scale-3d": ["scale-3d"],
      skew: [[skew: scale_skew()]],
      "skew-x": [["skew-x": scale_skew()]],
      "skew-y": [["skew-y": scale_skew()]],
      transform: [
        [
          transform: [
            &Twm.is_arbitrary_variable/1,
            &Twm.is_arbitrary_value/1,
            "",
            "none",
            "gpu",
            "cpu"
          ]
        ]
      ],
      "transform-origin": [[origin: scale_position_with_arbitrary()]],
      "transform-style": [[transform: ["3d", "flat"]]],
      translate: [[translate: scale_translate()]],
      "translate-x": [["translate-x": scale_translate()]],
      "translate-y": [["translate-y": scale_translate()]],
      "translate-z": [["translate-z": scale_translate()]],
      "translate-none": ["translate-none"],

      # Interactivity
      accent: [[accent: scale_color()]],
      appearance: [[appearance: ["none", "auto"]]],
      "caret-color": [[caret: scale_color()]],
      "color-scheme": [
        [scheme: ["normal", "dark", "light", "light-dark", "only-dark", "only-light"]]
      ],
      cursor: [
        [
          cursor: [
            "auto",
            "default",
            "pointer",
            "wait",
            "text",
            "move",
            "help",
            "not-allowed",
            "none",
            "context-menu",
            "progress",
            "cell",
            "crosshair",
            "vertical-text",
            "alias",
            "copy",
            "no-drop",
            "grab",
            "grabbing",
            "all-scroll",
            "col-resize",
            "row-resize",
            "n-resize",
            "e-resize",
            "s-resize",
            "w-resize",
            "ne-resize",
            "nw-resize",
            "se-resize",
            "sw-resize",
            "ew-resize",
            "ns-resize",
            "nesw-resize",
            "nwse-resize",
            "zoom-in",
            "zoom-out",
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],
      "pointer-events": [["pointer-events": ["none", "auto"]]],
      resize: [[resize: ["none", "y", "x", ""]]],
      "scroll-behavior": [[scroll: ["auto", "smooth"]]],
      "scroll-m": [["scroll-m": scale_margin()]],
      "scroll-mx": [["scroll-mx": scale_margin()]],
      "scroll-my": [["scroll-my": scale_margin()]],
      "scroll-ms": [["scroll-ms": scale_margin()]],
      "scroll-me": [["scroll-me": scale_margin()]],
      "scroll-mt": [["scroll-mt": scale_margin()]],
      "scroll-mr": [["scroll-mr": scale_margin()]],
      "scroll-mb": [["scroll-mb": scale_margin()]],
      "scroll-ml": [["scroll-ml": scale_margin()]],
      "scroll-p": [["scroll-p": scale_unambiguous_spacing()]],
      "scroll-px": [["scroll-px": scale_unambiguous_spacing()]],
      "scroll-py": [["scroll-py": scale_unambiguous_spacing()]],
      "scroll-ps": [["scroll-ps": scale_unambiguous_spacing()]],
      "scroll-pe": [["scroll-pe": scale_unambiguous_spacing()]],
      "scroll-pt": [["scroll-pt": scale_unambiguous_spacing()]],
      "scroll-pr": [["scroll-pr": scale_unambiguous_spacing()]],
      "scroll-pb": [["scroll-pb": scale_unambiguous_spacing()]],
      "scroll-pl": [["scroll-pl": scale_unambiguous_spacing()]],
      "snap-align": [[snap: ["start", "end", "center", "align-none"]]],
      "snap-stop": [[snap: ["normal", "always"]]],
      "snap-type": [[snap: ["none", "x", "y", "both"]]],
      "snap-strictness": [[snap: ["mandatory", "proximity"]]],
      touch: [[touch: ["auto", "none", "manipulation"]]],
      "touch-x": [[touch: ["pan-x", "pan-left", "pan-right"]]],
      "touch-y": [[touch: ["pan-y", "pan-up", "pan-down"]]],
      "touch-pz": [[touch: ["pinch-zoom"]]],
      "user-select": [[select: ["none", "text", "all", "auto"]]],
      "will-change": [
        [
          "will-change": [
            "auto",
            "scroll",
            "contents",
            "transform",
            &Twm.is_arbitrary_value/1
          ]
        ]
      ],

      # SVG
      fill: [[fill: ["none"] ++ scale_color()]],
      "stroke-w": [
        [
          stroke: [
            &Twm.is_number/1,
            &Twm.is_arbitrary_variable_length/1,
            &Twm.is_arbitrary_length/1,
            &Twm.is_arbitrary_number/1
          ]
        ]
      ],
      stroke: [[stroke: ["none"] ++ scale_color()]],
      # "stroke-width": [%{stroke: [&Twm.is_number/1, &Twm.is_arbitrary_value/1]}],

      # Accessibility
      "forced-color-adjust": [["forced-color-adjust": ["auto", "none"]]],

      # v4.0+ Features
      "field-sizing": [["field-sizing": ["content", "fixed"]]],
      "mask-composite": [[mask: ["add", "subtract", "intersect", "exclude"]]],
      "mask-type": [["mask-type": ["luminance", "alpha"]]],
      "inset-ring": [
        ["inset-ring": ["", &Twm.is_number/1, &Twm.is_arbitrary_value/1]],
        ["inset-ring-color": scale_color()]
      ],
      "text-shadow": [
        ["text-shadow": ["none", "sm", "md", "lg", "xl", "2xl", &Twm.is_arbitrary_value/1]]
      ],
      "text-shadow-color": [
        ["text-shadow": scale_color()]
      ],
      "mask-position": [
        ["mask-position": [&Twm.is_arbitrary_value/1, &Twm.is_arbitrary_variable/1]],
        [
          mask: [
            &Twm.is_arbitrary_position/1,
            &Twm.is_arbitrary_variable_position/1,
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right"
          ]
        ]
      ],
      "mask-size": [
        ["mask-size": [&Twm.is_arbitrary_value/1, &Twm.is_arbitrary_variable/1]],
        [
          mask: [
            &Twm.is_arbitrary_size/1,
            &Twm.is_arbitrary_variable_size/1,
            "auto",
            "cover",
            "contain"
          ]
        ]
      ],
      "mask-image": [
        [mask: ["none", &Twm.is_arbitrary_value/1, &Twm.is_arbitrary_variable/1]]
      ],
      "mask-image-linear-pos": [
        ["mask-linear": [&Twm.is_number/1]]
      ],
      "mask-image-linear-from-pos": [
        ["mask-linear-from": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "mask-image-linear-to-pos": [
        ["mask-linear-to": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "mask-image-linear-from-color": [
        ["mask-linear-from-color": scale_color()]
      ],
      "mask-image-linear-to-color": [
        ["mask-linear-to-color": scale_color()]
      ],
      "mask-image-t-from-pos": [
        ["mask-t-from": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "mask-image-t-to-pos": [
        ["mask-t-to": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "mask-image-t-from-color": [
        ["mask-t-from-color": scale_color()]
      ],
      "mask-image-radial": [
        ["mask-radial": [&Twm.is_arbitrary_value/1, &Twm.is_arbitrary_variable/1]]
      ],
      "mask-image-radial-from-pos": [
        ["mask-radial-from": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "mask-image-radial-to-pos": [
        ["mask-radial-to": [&Twm.is_number/1, &Twm.is_arbitrary_value/1]]
      ],
      "mask-image-radial-from-color": [
        ["mask-radial-from-color": scale_color()]
      ]
    ]
  end

  defp conflicting_class_groups do
    [
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
      "fvn-fraction": ["fvn-normal"],
      "line-clamp": ["display", "overflow"],
      rounded: [
        "rounded-s",
        "rounded-e",
        "rounded-t",
        "rounded-r",
        "rounded-b",
        "rounded-l",
        "rounded-ss",
        "rounded-se",
        "rounded-ee",
        "rounded-es",
        "rounded-tl",
        "rounded-tr",
        "rounded-br",
        "rounded-bl"
      ],
      "rounded-s": ["rounded-ss", "rounded-es"],
      "rounded-e": ["rounded-se", "rounded-ee"],
      "rounded-t": ["rounded-tl", "rounded-tr"],
      "rounded-r": ["rounded-tr", "rounded-br"],
      "rounded-b": ["rounded-br", "rounded-bl"],
      "rounded-l": ["rounded-tl", "rounded-bl"],
      "border-spacing": ["border-spacing-x", "border-spacing-y"],
      "border-w": [
        "border-w-x",
        "border-w-y",
        "border-w-s",
        "border-w-e",
        "border-w-t",
        "border-w-r",
        "border-w-b",
        "border-w-l"
      ],
      "border-w-x": ["border-w-r", "border-w-l"],
      "border-w-y": ["border-w-t", "border-w-b"],
      "border-color": [
        "border-color-x",
        "border-color-y",
        "border-color-s",
        "border-color-e",
        "border-color-t",
        "border-color-r",
        "border-color-b",
        "border-color-l"
      ],
      "border-color-x": ["border-color-r", "border-color-l"],
      "border-color-y": ["border-color-t", "border-color-b"],
      translate: ["translate-x", "translate-y", "translate-none"],
      "translate-none": ["translate", "translate-x", "translate-y", "translate-z"],
      "scroll-m": [
        "scroll-mx",
        "scroll-my",
        "scroll-ms",
        "scroll-me",
        "scroll-mt",
        "scroll-mr",
        "scroll-mb",
        "scroll-ml"
      ],
      "scroll-mx": ["scroll-mr", "scroll-ml"],
      "scroll-my": ["scroll-mt", "scroll-mb"],
      "scroll-p": [
        "scroll-px",
        "scroll-py",
        "scroll-ps",
        "scroll-pe",
        "scroll-pt",
        "scroll-pr",
        "scroll-pb",
        "scroll-pl"
      ],
      "scroll-px": ["scroll-pr", "scroll-pl"],
      "scroll-py": ["scroll-pt", "scroll-pb"],
      touch: ["touch-x", "touch-y", "touch-pz"],
      "touch-x": ["touch"],
      "touch-y": ["touch"],
      "touch-pz": ["touch"],

      # v4.0+ conflicting groups
      "text-shadow": ["text-shadow-color"],
      "mask-image": ["mask-position", "mask-size"]
    ]
  end

  defp conflicting_class_group_modifiers do
    [
      "font-size": ["leading"]
    ]
  end

  defp order_sensitive_modifiers do
    [
      "*",
      "**",
      "after",
      "backdrop",
      "before",
      "details-content",
      "file",
      "first-letter",
      "first-line",
      "marker",
      "placeholder",
      "selection"
    ]
  end
end
