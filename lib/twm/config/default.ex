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
      "none",
      "subgrid",
      &Twm.is_integer/1,
      &Twm.is_arbitrary_value/1
    ]
  end

  defp scale_grid_col_row_start_and_end do
    [
      "auto",
      &Twm.is_integer/1,
      &Twm.is_arbitrary_value/1
    ]
  end

  # Configuration components
  defp theme do
    %{
      color: nil,
      font: nil,
      text: nil,
      font_weight: nil,
      tracking: nil,
      leading: nil,
      breakpoint: nil,
      container: nil,
      spacing: %{
        "0" => "0px",
        "px" => "1px",
        "0.5" => "0.125rem",
        "1" => "0.25rem",
        "1.5" => "0.375rem",
        "2" => "0.5rem",
        "2.5" => "0.625rem",
        "3" => "0.75rem",
        "3.5" => "0.875rem",
        "4" => "1rem",
        "5" => "1.25rem",
        "6" => "1.5rem",
        "7" => "1.75rem",
        "8" => "2rem",
        "9" => "2.25rem",
        "10" => "2.5rem",
        "11" => "2.75rem",
        "12" => "3rem",
        "14" => "3.5rem",
        "16" => "4rem",
        "20" => "5rem",
        "24" => "6rem",
        "28" => "7rem",
        "32" => "8rem",
        "36" => "9rem",
        "40" => "10rem",
        "44" => "11rem",
        "48" => "12rem",
        "52" => "13rem",
        "56" => "14rem",
        "60" => "15rem",
        "64" => "16rem",
        "72" => "18rem",
        "80" => "20rem",
        "96" => "24rem"
      },
      radius: nil,
      shadow: nil,
      inset_shadow: nil,
      text_shadow: nil,
      drop_shadow: nil,
      blur: nil,
      perspective: nil,
      aspect: nil,
      ease: nil,
      animate: nil
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
      float: ["right", "left", "none"],
      clear: ["left", "right", "both", "none"],
      inset: scale_inset(),
      inset_x: scale_inset(),
      inset_y: scale_inset(),
      start: scale_inset(),
      end: scale_inset(),
      top: scale_inset(),
      right: scale_inset(),
      bottom: scale_inset(),
      left: scale_inset(),
      visibility: ["visible", "invisible", "collapse"],
      z: ["auto", &Twm.is_integer/1, &Twm.is_arbitrary_value/1],

      # Flexbox and Grid
      flex: [
        "1",
        "auto",
        "initial",
        "none",
        &Twm.is_arbitrary_value/1
      ],
      flex_direction: ["row", "row-reverse", "col", "col-reverse"],
      flex_wrap: ["wrap", "wrap-reverse", "nowrap"],
      grow: ["0", "1", &Twm.is_arbitrary_value/1],
      shrink: ["0", "1", &Twm.is_arbitrary_value/1],
      basis: [
        "0",
        "1",
        "auto",
        "full",
        &Twm.is_arbitrary_value/1,
        theme_spacing()
      ],

      # Spacing - using explicit class paths instead of theme getters
      p: [
        "p-0", "p-px", "p-0.5", "p-1", "p-1.5", "p-2", "p-2.5", "p-3", "p-3.5", "p-4",
        "p-5", "p-6", "p-7", "p-8", "p-9", "p-10", "p-11", "p-12", "p-14", "p-16",
        "p-20", "p-24", "p-28", "p-32", "p-36", "p-40", "p-44", "p-48", "p-52", "p-56",
        "p-60", "p-64", "p-72", "p-80", "p-96", &Twm.is_arbitrary_value/1
      ],
      px: [
        "px-0", "px-px", "px-0.5", "px-1", "px-1.5", "px-2", "px-2.5", "px-3", "px-3.5", "px-4",
        "px-5", "px-6", "px-7", "px-8", "px-9", "px-10", "px-11", "px-12", "px-14", "px-16",
        "px-20", "px-24", "px-28", "px-32", "px-36", "px-40", "px-44", "px-48", "px-52", "px-56",
        "px-60", "px-64", "px-72", "px-80", "px-96", &Twm.is_arbitrary_value/1
      ],
      py: [
        "py-0", "py-px", "py-0.5", "py-1", "py-1.5", "py-2", "py-2.5", "py-3", "py-3.5", "py-4",
        "py-5", "py-6", "py-7", "py-8", "py-9", "py-10", "py-11", "py-12", "py-14", "py-16",
        "py-20", "py-24", "py-28", "py-32", "py-36", "py-40", "py-44", "py-48", "py-52", "py-56",
        "py-60", "py-64", "py-72", "py-80", "py-96", &Twm.is_arbitrary_value/1
      ],
      ps: [
        "ps-0", "ps-px", "ps-0.5", "ps-1", "ps-1.5", "ps-2", "ps-2.5", "ps-3", "ps-3.5", "ps-4",
        "ps-5", "ps-6", "ps-7", "ps-8", "ps-9", "ps-10", "ps-11", "ps-12", "ps-14", "ps-16",
        "ps-20", "ps-24", "ps-28", "ps-32", "ps-36", "ps-40", "ps-44", "ps-48", "ps-52", "ps-56",
        "ps-60", "ps-64", "ps-72", "ps-80", "ps-96", &Twm.is_arbitrary_value/1
      ],
      pe: [
        "pe-0", "pe-px", "pe-0.5", "pe-1", "pe-1.5", "pe-2", "pe-2.5", "pe-3", "pe-3.5", "pe-4",
        "pe-5", "pe-6", "pe-7", "pe-8", "pe-9", "pe-10", "pe-11", "pe-12", "pe-14", "pe-16",
        "pe-20", "pe-24", "pe-28", "pe-32", "pe-36", "pe-40", "pe-44", "pe-48", "pe-52", "pe-56",
        "pe-60", "pe-64", "pe-72", "pe-80", "pe-96", &Twm.is_arbitrary_value/1
      ],
      pt: [
        "pt-0", "pt-px", "pt-0.5", "pt-1", "pt-1.5", "pt-2", "pt-2.5", "pt-3", "pt-3.5", "pt-4",
        "pt-5", "pt-6", "pt-7", "pt-8", "pt-9", "pt-10", "pt-11", "pt-12", "pt-14", "pt-16",
        "pt-20", "pt-24", "pt-28", "pt-32", "pt-36", "pt-40", "pt-44", "pt-48", "pt-52", "pt-56",
        "pt-60", "pt-64", "pt-72", "pt-80", "pt-96", &Twm.is_arbitrary_value/1
      ],
      pr: [
        "pr-0", "pr-px", "pr-0.5", "pr-1", "pr-1.5", "pr-2", "pr-2.5", "pr-3", "pr-3.5", "pr-4",
        "pr-5", "pr-6", "pr-7", "pr-8", "pr-9", "pr-10", "pr-11", "pr-12", "pr-14", "pr-16",
        "pr-20", "pr-24", "pr-28", "pr-32", "pr-36", "pr-40", "pr-44", "pr-48", "pr-52", "pr-56",
        "pr-60", "pr-64", "pr-72", "pr-80", "pr-96", &Twm.is_arbitrary_value/1
      ],
      pb: [
        "pb-0", "pb-px", "pb-0.5", "pb-1", "pb-1.5", "pb-2", "pb-2.5", "pb-3", "pb-3.5", "pb-4",
        "pb-5", "pb-6", "pb-7", "pb-8", "pb-9", "pb-10", "pb-11", "pb-12", "pb-14", "pb-16",
        "pb-20", "pb-24", "pb-28", "pb-32", "pb-36", "pb-40", "pb-44", "pb-48", "pb-52", "pb-56",
        "pb-60", "pb-64", "pb-72", "pb-80", "pb-96", &Twm.is_arbitrary_value/1
      ],
      pl: [
        "pl-0", "pl-px", "pl-0.5", "pl-1", "pl-1.5", "pl-2", "pl-2.5", "pl-3", "pl-3.5", "pl-4",
        "pl-5", "pl-6", "pl-7", "pl-8", "pl-9", "pl-10", "pl-11", "pl-12", "pl-14", "pl-16",
        "pl-20", "pl-24", "pl-28", "pl-32", "pl-36", "pl-40", "pl-44", "pl-48", "pl-52", "pl-56",
        "pl-60", "pl-64", "pl-72", "pl-80", "pl-96", &Twm.is_arbitrary_value/1
      ],
      m: [
        "m-0", "m-px", "m-0.5", "m-1", "m-1.5", "m-2", "m-2.5", "m-3", "m-3.5", "m-4",
        "m-5", "m-6", "m-7", "m-8", "m-9", "m-10", "m-11", "m-12", "m-14", "m-16",
        "m-20", "m-24", "m-28", "m-32", "m-36", "m-40", "m-44", "m-48", "m-52", "m-56",
        "m-60", "m-64", "m-72", "m-80", "m-96", "m-auto", &Twm.is_arbitrary_value/1
      ],
      mx: [
        "mx-0", "mx-px", "mx-0.5", "mx-1", "mx-1.5", "mx-2", "mx-2.5", "mx-3", "mx-3.5", "mx-4",
        "mx-5", "mx-6", "mx-7", "mx-8", "mx-9", "mx-10", "mx-11", "mx-12", "mx-14", "mx-16",
        "mx-20", "mx-24", "mx-28", "mx-32", "mx-36", "mx-40", "mx-44", "mx-48", "mx-52", "mx-56",
        "mx-60", "mx-64", "mx-72", "mx-80", "mx-96", "mx-auto", &Twm.is_arbitrary_value/1
      ],
      my: [
        "my-0", "my-px", "my-0.5", "my-1", "my-1.5", "my-2", "my-2.5", "my-3", "my-3.5", "my-4",
        "my-5", "my-6", "my-7", "my-8", "my-9", "my-10", "my-11", "my-12", "my-14", "my-16",
        "my-20", "my-24", "my-28", "my-32", "my-36", "my-40", "my-44", "my-48", "my-52", "my-56",
        "my-60", "my-64", "my-72", "my-80", "my-96", "my-auto", &Twm.is_arbitrary_value/1
      ],
      ms: [
        "ms-0", "ms-px", "ms-0.5", "ms-1", "ms-1.5", "ms-2", "ms-2.5", "ms-3", "ms-3.5", "ms-4",
        "ms-5", "ms-6", "ms-7", "ms-8", "ms-9", "ms-10", "ms-11", "ms-12", "ms-14", "ms-16",
        "ms-20", "ms-24", "ms-28", "ms-32", "ms-36", "ms-40", "ms-44", "ms-48", "ms-52", "ms-56",
        "ms-60", "ms-64", "ms-72", "ms-80", "ms-96", "ms-auto", &Twm.is_arbitrary_value/1
      ],
      me: [
        "me-0", "me-px", "me-0.5", "me-1", "me-1.5", "me-2", "me-2.5", "me-3", "me-3.5", "me-4",
        "me-5", "me-6", "me-7", "me-8", "me-9", "me-10", "me-11", "me-12", "me-14", "me-16",
        "me-20", "me-24", "me-28", "me-32", "me-36", "me-40", "me-44", "me-48", "me-52", "me-56",
        "me-60", "me-64", "me-72", "me-80", "me-96", "me-auto", &Twm.is_arbitrary_value/1
      ],
      mt: [
        "mt-0", "mt-px", "mt-0.5", "mt-1", "mt-1.5", "mt-2", "mt-2.5", "mt-3", "mt-3.5", "mt-4",
        "mt-5", "mt-6", "mt-7", "mt-8", "mt-9", "mt-10", "mt-11", "mt-12", "mt-14", "mt-16",
        "mt-20", "mt-24", "mt-28", "mt-32", "mt-36", "mt-40", "mt-44", "mt-48", "mt-52", "mt-56",
        "mt-60", "mt-64", "mt-72", "mt-80", "mt-96", "mt-auto", &Twm.is_arbitrary_value/1
      ],
      mr: [
        "mr-0", "mr-px", "mr-0.5", "mr-1", "mr-1.5", "mr-2", "mr-2.5", "mr-3", "mr-3.5", "mr-4",
        "mr-5", "mr-6", "mr-7", "mr-8", "mr-9", "mr-10", "mr-11", "mr-12", "mr-14", "mr-16",
        "mr-20", "mr-24", "mr-28", "mr-32", "mr-36", "mr-40", "mr-44", "mr-48", "mr-52", "mr-56",
        "mr-60", "mr-64", "mr-72", "mr-80", "mr-96", "mr-auto", &Twm.is_arbitrary_value/1
      ],
      mb: [
        "mb-0", "mb-px", "mb-0.5", "mb-1", "mb-1.5", "mb-2", "mb-2.5", "mb-3", "mb-3.5", "mb-4",
        "mb-5", "mb-6", "mb-7", "mb-8", "mb-9", "mb-10", "mb-11", "mb-12", "mb-14", "mb-16",
        "mb-20", "mb-24", "mb-28", "mb-32", "mb-36", "mb-40", "mb-44", "mb-48", "mb-52", "mb-56",
        "mb-60", "mb-64", "mb-72", "mb-80", "mb-96", "mb-auto", &Twm.is_arbitrary_value/1
      ],
      ml: [
        "ml-0", "ml-px", "ml-0.5", "ml-1", "ml-1.5", "ml-2", "ml-2.5", "ml-3", "ml-3.5", "ml-4",
        "ml-5", "ml-6", "ml-7", "ml-8", "ml-9", "ml-10", "ml-11", "ml-12", "ml-14", "ml-16",
        "ml-20", "ml-24", "ml-28", "ml-32", "ml-36", "ml-40", "ml-44", "ml-48", "ml-52", "ml-56",
        "ml-60", "ml-64", "ml-72", "ml-80", "ml-96", "ml-auto", &Twm.is_arbitrary_value/1
      ],

      # Grid
      grid_cols: [
        %{
          grid_cols: scale_grid_template_cols_rows()
        }
      ],
      grid_rows: [
        %{
          grid_rows: scale_grid_template_cols_rows()
        }
      ],
      col_start: [
        %{
          col_start: scale_grid_col_row_start_and_end()
        }
      ],
      col_end: [
        %{
          col_end: scale_grid_col_row_start_and_end()
        }
      ],
      row_start: [
        %{
          row_start: scale_grid_col_row_start_and_end()
        }
      ],
      row_end: [
        %{
          row_end: scale_grid_col_row_start_and_end()
        }
      ],

      # Overflow
      overflow: [
        %{
          overflow: scale_overflow()
        }
      ],
      overflow_x: [
        %{
          overflow_x: scale_overflow()
        }
      ],
      overflow_y: [
        %{
          overflow_y: scale_overflow()
        }
      ],

      # Typography
      font_size: [
        %{
          text: ["xs", "sm", "base", "lg", "xl", "2xl", "3xl", "4xl", "5xl", "6xl", "7xl", "8xl", "9xl"]
        }
      ],
      font_weight: [
        %{
          font: ["thin", "extralight", "light", "normal", "medium", "semibold", "bold", "extrabold", "black"]
        }
      ],
      text_align: ["left", "center", "right", "justify", "start", "end"],
      
      # Additional essential class groups can be added here as needed
    }
  end

  defp conflicting_class_groups do
    %{
      display: [],
      position: [],
      float: ["clear"],
      clear: ["float"],
      inset: ["inset_x", "inset_y", "top", "right", "bottom", "left", "start", "end"],
      inset_x: ["right", "left", "start", "end", "inset"],
      inset_y: ["top", "bottom", "inset"],
      top: ["inset", "inset_y"],
      right: ["inset", "inset_x", "end"],
      bottom: ["inset", "inset_y"],
      left: ["inset", "inset_x", "start"],
      start: ["inset", "inset_x", "left"],
      end: ["inset", "inset_x", "right"],
      
      # Spacing conflicts
      p: ["px", "py", "ps", "pe", "pt", "pr", "pb", "pl"],
      px: ["p", "pr", "pl"],
      py: ["p", "pt", "pb"],
      ps: ["p", "pl"],
      pe: ["p", "pr"],
      pt: ["p", "py"],
      pr: ["p", "px", "pe"],
      pb: ["p", "py"],
      pl: ["p", "px", "ps"],
      m: ["mx", "my", "ms", "me", "mt", "mr", "mb", "ml"],
      mx: ["m", "mr", "ml"],
      my: ["m", "mt", "mb"],
      ms: ["m", "ml"],
      me: ["m", "mr"],
      mt: ["m", "my"],
      mr: ["m", "mx", "me"],
      mb: ["m", "my"],
      ml: ["m", "mx", "ms"],
      
      # Grid conflicts
      grid_cols: [],
      grid_rows: [],
      col_start: [],
      col_end: [],
      row_start: [],
      row_end: [],
      
      # Overflow conflicts
      overflow: ["overflow_x", "overflow_y"],
      overflow_x: ["overflow"],
      overflow_y: ["overflow"],
      
      # Typography conflicts
      font_size: ["leading"],
      font_weight: [],
      text_align: []
    }
  end

  defp conflicting_class_group_modifiers do
    %{
      font_size: ["leading"]
    }
  end

  defp order_sensitive_modifiers do
    [
      "first",
      "last",
      "odd",
      "even",
      "first-of-type",
      "last-of-type",
      "only-of-type",
      "only",
      "visited",
      "target",
      "open",
      "default",
      "checked",
      "indeterminate",
      "placeholder-shown",
      "autofill",
      "required",
      "valid",
      "invalid",
      "in-range",
      "out-of-range",
      "read-only",
      "empty",
      "focus-within",
      "hover",
      "focus",
      "focus-visible",
      "active",
      "enabled",
      "disabled",
      "group-first",
      "group-last",
      "group-odd",
      "group-even",
      "group-first-of-type",
      "group-last-of-type",
      "group-only-of-type",
      "group-only",
      "group-visited",
      "group-target",
      "group-open",
      "group-default",
      "group-checked",
      "group-indeterminate",
      "group-placeholder-shown",
      "group-autofill",
      "group-required",
      "group-valid",
      "group-invalid",
      "group-in-range",
      "group-out-of-range",
      "group-read-only",
      "group-empty",
      "group-focus-within",
      "group-hover",
      "group-focus",
      "group-focus-visible",
      "group-active",
      "group-enabled",
      "group-disabled",
      "peer-first",
      "peer-last",
      "peer-odd",
      "peer-even",
      "peer-first-of-type",
      "peer-last-of-type",
      "peer-only-of-type",
      "peer-only",
      "peer-visited",
      "peer-target",
      "peer-open",
      "peer-default",
      "peer-checked",
      "peer-indeterminate",
      "peer-placeholder-shown",
      "peer-autofill",
      "peer-required",
      "peer-valid",
      "peer-invalid",
      "peer-in-range",
      "peer-out-of-range",
      "peer-read-only",
      "peer-empty",
      "peer-focus-within",
      "peer-hover",
      "peer-focus",
      "peer-focus-visible",
      "peer-active",
      "peer-enabled",
      "peer-disabled",
      "selection",
      "markers",
      "placeholder",
      "before",
      "after",
      "file",
      "backdrop",
      "first-letter",
      "first-line",
      "dialog",
      "dark",
      "motion-reduce",
      "motion-safe",
      "contrast-more",
      "contrast-less",
      "print",
      "landscape",
      "portrait",
      "ltr",
      "rtl"
    ]
  end
end
