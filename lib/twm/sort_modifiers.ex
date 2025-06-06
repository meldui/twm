defmodule Twm.SortModifiers do
  @moduledoc """
  Sorts modifiers according to following schema:
  - Predefined modifiers are sorted alphabetically
  - When an arbitrary variant appears, it must be preserved which modifiers are before and after it
  """

  @doc """
  Creates a sort modifiers function based on the provided configuration.

  The returned function sorts modifiers while preserving the order of position-sensitive
  modifiers (those that start with '[' or are in the order_sensitive_modifiers list).

  ## Parameters

    * `config` - A map containing the `order_sensitive_modifiers` key

  ## Returns

  A function that takes a list of modifiers and returns them sorted.

  ## Examples

      iex> config = %{order_sensitive_modifiers: ["hover", "focus"]}
      iex> sort_fn = Twm.SortModifiers.create_sort_modifiers(config)
      iex> sort_fn.(["d", "hover", "c"])
      ["d", "hover", "c"]

      iex> config = %{order_sensitive_modifiers: ["hover"]}
      iex> sort_fn = Twm.SortModifiers.create_sort_modifiers(config)
      iex> sort_fn.(["[data-test]", "d", "c"])
      ["[data-test]", "c", "d"]

  """
  @spec create_sort_modifiers(map()) :: (list(String.t()) -> list(String.t()))
  def create_sort_modifiers(config) do
    order_sensitive_modifiers_set =
      config
      |> Map.get(:order_sensitive_modifiers, [])
      |> MapSet.new()

    fn modifiers ->
      sort_modifiers(modifiers, order_sensitive_modifiers_set)
    end
  end

  @doc """
  Sorts a list of modifiers according to the sorting rules.

  ## Parameters

    * `modifiers` - List of modifier strings to sort
    * `order_sensitive_modifiers_set` - MapSet of modifiers that are position-sensitive

  ## Returns

  A sorted list of modifiers.

  ## Examples

      iex> order_sensitive = MapSet.new(["hover", "focus"])
      iex> Twm.SortModifiers.sort_modifiers(["d", "hover", "c"], order_sensitive)
      ["d", "hover", "c"]

  """
  @spec sort_modifiers(list(String.t()), MapSet.t()) :: list(String.t())
  def sort_modifiers(modifiers, _order_sensitive_modifiers_set) when length(modifiers) <= 1 do
    modifiers
  end

  def sort_modifiers(modifiers, order_sensitive_modifiers_set) do
    {sorted_modifiers, unsorted_modifiers} =
      Enum.reduce(modifiers, {[], []}, fn modifier, {sorted_acc, unsorted_acc} ->
        is_position_sensitive =
          String.starts_with?(modifier, "[") or
            MapSet.member?(order_sensitive_modifiers_set, modifier)

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
