defmodule Twm.SortModifiers do
  @moduledoc """
  Sorts modifiers according to following schema:
  - Predefined modifiers are sorted alphabetically
  - When an arbitrary variant appears, it must be preserved which modifiers are before and after it
  """

  alias Twm.Context.ModifierSortingContext

  @doc """
  Creates a context for sorting modifiers based on the provided configuration.

  The context holds the configuration data needed for modifier sorting operations.

  ## Parameters

    * `config` - A keyword list containing the `order_sensitive_modifiers` key

  ## Returns

  A Context struct containing the sorting configuration.

  ## Examples

      iex> config = Twm.Config.new([order_sensitive_modifiers: ["hover", "focus"]])
      iex> context = Twm.SortModifiers.create_sort_modifiers(config)
      iex> Twm.SortModifiers.sort_modifiers(["d", "hover", "c"], context)
      ["d", "hover", "c"]

      iex> config = Twm.Config.new([order_sensitive_modifiers: ["hover"]])
      iex> context = Twm.SortModifiers.create_sort_modifiers(config)
      iex> Twm.SortModifiers.sort_modifiers(["[data-test]", "d", "c"], context)
      ["[data-test]", "c", "d"]

  """
  @spec create_sort_modifiers(Twm.Config.t()) :: ModifierSortingContext.t()
  def create_sort_modifiers(config) do
    order_sensitive_modifiers_set =
      config.order_sensitive_modifiers ||
        []
        |> MapSet.new()

    %ModifierSortingContext{
      order_sensitive_modifiers_set: order_sensitive_modifiers_set
    }
  end

  @doc """
  Sorts a list of modifiers using the provided context.

  ## Parameters

    * `modifiers` - List of modifier strings to sort
    * `context` - Context struct containing sorting configuration

  ## Returns

  A sorted list of modifiers.

  ## Examples

      iex> config = Twm.Config.new([order_sensitive_modifiers: ["hover"]])
      iex> context = Twm.SortModifiers.create_sort_modifiers(config)
      iex> Twm.SortModifiers.sort_modifiers(["d", "hover", "c"], context)
      ["d", "hover", "c"]

  """
  @spec sort_modifiers(list(String.t()), ModifierSortingContext.t()) :: list(String.t())
  def sort_modifiers(modifiers, %ModifierSortingContext{
        order_sensitive_modifiers_set: order_sensitive_modifiers_set
      }) do
    sort_modifiers_with_set(modifiers, order_sensitive_modifiers_set)
  end

  # Internal function to sort modifiers with a MapSet
  @spec sort_modifiers_with_set(list(String.t()), MapSet.t()) :: list(String.t())
  defp sort_modifiers_with_set(modifiers, _order_sensitive_modifiers_set)
       when length(modifiers) <= 1 do
    modifiers
  end

  defp sort_modifiers_with_set(modifiers, order_sensitive_modifiers_set) do
    {sorted_modifiers, unsorted_modifiers} =
      Enum.reduce(modifiers, {[], []}, fn modifier, {sorted_acc, unsorted_acc} ->
        is_position_sensitive =
          String.starts_with?(modifier, "[") or
            Enum.member?(order_sensitive_modifiers_set, modifier)

        if is_position_sensitive do
          # When we encounter a position-sensitive modifier, we sort the accumulated
          # unsorted modifiers and add them to the result, then add the position-sensitive modifier
          sorted_unsorted = Enum.sort(unsorted_acc)
          {sorted_acc ++ sorted_unsorted ++ [modifier], []}
        else
          # Regular modifier, add to unsorted accumulator
          {sorted_acc, unsorted_acc ++ [modifier]}
        end
      end)

    # Sort any remaining unsorted modifiers and append them
    sorted_modifiers ++ Enum.sort(unsorted_modifiers)
  end
end
