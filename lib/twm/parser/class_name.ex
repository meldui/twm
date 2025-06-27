defmodule Twm.Parser.ClassName do
  @moduledoc """
  Provides functionality for parsing Tailwind CSS class names into their components.

  This module is responsible for breaking down class names into their modifiers,
  base class name, and handling special cases like the important modifier.
  """

  alias Twm.Types
  alias Twm.Context.ClassParsingContext

  @important_modifier "!"
  @modifier_separator ":"
  @modifier_separator_length String.length(@modifier_separator)

  @doc """
  Creates a context for parsing class names based on the provided configuration.

  ## Parameters

  * `config` - A keyword list containing configuration options like prefix and experimental parser

  ## Returns

  * A Context struct containing the parsing configuration
  """
  @spec create_parse_class_name(Types.config()) :: Context.t()
  def create_parse_class_name(config) do
    prefix = Keyword.get(config, :prefix)
    experimental_parse_class_name = Keyword.get(config, :experimental_parse_class_name)

    %ClassParsingContext{
      prefix: prefix,
      experimental_parse_class_name: experimental_parse_class_name
    }
  end

  @doc """
  Parses a class name using the provided context.

  ## Parameters

  * `class_name` - The class name string to parse
  * `context` - The Context struct containing parsing configuration

  ## Returns

  * A map containing the parsed components of the class name
  """
  @spec parse_class_name(String.t(), ClassParsingContext.t()) :: Types.parsed_class_name()
  def parse_class_name(class_name, %ClassParsingContext{} = context) do
    # First check if experimental parser should be used
    if context.experimental_parse_class_name do
      context.experimental_parse_class_name.(%{
        class_name: class_name,
        parse_class_name: fn name -> parse_class_name_with_prefix(name, context) end
      })
    else
      parse_class_name_with_prefix(class_name, context)
    end
  end

  # Parse class name with prefix handling
  defp parse_class_name_with_prefix(class_name, %ClassParsingContext{prefix: nil}) do
    do_parse_class_name(class_name)
  end

  defp parse_class_name_with_prefix(class_name, %ClassParsingContext{prefix: prefix}) do
    full_prefix = prefix <> @modifier_separator

    if String.starts_with?(class_name, full_prefix) do
      class_name
      |> String.slice(String.length(full_prefix)..-1//1)
      |> do_parse_class_name()
    else
      %{
        is_external: true,
        modifiers: [],
        has_important_modifier: false,
        base_class_name: class_name,
        maybe_postfix_modifier_position: nil
      }
    end
  end

  @doc """
  Parse a class name into its constituent parts.

  Inspired by `splitAtTopLevelOnly` used in Tailwind CSS.
  See: https://github.com/tailwindlabs/tailwindcss/blob/v3.2.2/src/util/splitAtTopLevelOnly.js

  ## Parameters

  * `class_name` - The class name string to parse

  ## Returns

  * A map containing the parsed components of the class name
  """
  @spec do_parse_class_name(String.t()) :: Types.parsed_class_name()
  def do_parse_class_name(class_name) do
    {modifiers, modifier_start, postfix_modifier_position} =
      find_modifiers(class_name)

    base_class_name_with_important_modifier =
      if Enum.empty?(modifiers) do
        class_name
      else
        String.slice(class_name, modifier_start..-1//1)
      end

    base_class_name_stripped_important =
      strip_important_modifier(base_class_name_with_important_modifier)

    has_important_modifier =
      base_class_name_stripped_important != base_class_name_with_important_modifier

    maybe_postfix_modifier_position =
      if postfix_modifier_position && postfix_modifier_position > modifier_start do
        postfix_modifier_position - modifier_start
      else
        nil
      end

    # Strip postfix modifier from base class name if present
    # Only strip if there's actually a "/" at the postfix modifier position
    base_class_name =
      if maybe_postfix_modifier_position &&
           String.at(base_class_name_stripped_important, maybe_postfix_modifier_position) == "/" do
        String.slice(base_class_name_stripped_important, 0, maybe_postfix_modifier_position)
      else
        base_class_name_stripped_important
      end

    %{
      is_external: false,
      modifiers: modifiers,
      has_important_modifier: has_important_modifier,
      base_class_name: base_class_name,
      maybe_postfix_modifier_position: maybe_postfix_modifier_position
    }
  end

  @spec find_modifiers(String.t()) :: {[String.t()], non_neg_integer(), non_neg_integer() | nil}
  defp find_modifiers(class_name) do
    find_modifiers(class_name, 0, 0, 0, 0, [], nil)
  end

  defp find_modifiers(
         class_name,
         index,
         bracket_depth,
         paren_depth,
         modifier_start,
         modifiers,
         postfix_mod_pos
       ) do
    if index >= String.length(class_name) do
      {modifiers, modifier_start, postfix_mod_pos}
    else
      current_char = String.at(class_name, index)

      if bracket_depth == 0 && paren_depth == 0 do
        cond do
          current_char == @modifier_separator ->
            modifier = String.slice(class_name, modifier_start, index - modifier_start)

            find_modifiers(
              class_name,
              index + @modifier_separator_length,
              bracket_depth,
              paren_depth,
              index + @modifier_separator_length,
              modifiers ++ [modifier],
              postfix_mod_pos
            )

          current_char == "/" ->
            find_modifiers(
              class_name,
              index + 1,
              bracket_depth,
              paren_depth,
              modifier_start,
              modifiers,
              index
            )

          true ->
            update_depths(
              class_name,
              index,
              bracket_depth,
              paren_depth,
              modifier_start,
              modifiers,
              postfix_mod_pos,
              current_char
            )
        end
      else
        update_depths(
          class_name,
          index,
          bracket_depth,
          paren_depth,
          modifier_start,
          modifiers,
          postfix_mod_pos,
          current_char
        )
      end
    end
  end

  defp update_depths(
         class_name,
         index,
         bracket_depth,
         paren_depth,
         modifier_start,
         modifiers,
         postfix_mod_pos,
         current_char
       ) do
    {new_bracket_depth, new_paren_depth} =
      case current_char do
        "[" -> {bracket_depth + 1, paren_depth}
        "]" -> {bracket_depth - 1, paren_depth}
        "(" -> {bracket_depth, paren_depth + 1}
        ")" -> {bracket_depth, paren_depth - 1}
        _ -> {bracket_depth, paren_depth}
      end

    find_modifiers(
      class_name,
      index + 1,
      new_bracket_depth,
      new_paren_depth,
      modifier_start,
      modifiers,
      postfix_mod_pos
    )
  end

  @doc """
  Removes the important modifier from a class name.

  In Tailwind CSS, the important modifier can be at the end of the class name,
  or at the beginning in v3.

  ## Parameters

  * `base_class_name` - The class name to process

  ## Returns

  * The class name without the important modifier
  """
  @spec strip_important_modifier(String.t()) :: String.t()
  def strip_important_modifier(base_class_name) do
    cond do
      String.ends_with?(base_class_name, @important_modifier) ->
        String.slice(base_class_name, 0..-2//1)

      # In Tailwind CSS v3 the important modifier was at the start of the base class name
      # This is still supported for legacy reasons
      # See: https://github.com/dcastil/tailwind-merge/issues/513#issuecomment-2614029864
      String.starts_with?(base_class_name, @important_modifier) ->
        String.slice(base_class_name, 1..-1//1)

      true ->
        base_class_name
    end
  end
end
