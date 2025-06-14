defmodule Twm.SortModifiersTest do
  use ExUnit.Case, async: true
  doctest Twm.SortModifiers

  alias Twm.SortModifiers

  describe "create_sort_modifiers/1" do
    test "returns a function that sorts modifiers" do
      config = [order_sensitive_modifiers: ["hover", "focus"]]
      sort_fn = SortModifiers.create_sort_modifiers(config)

      assert is_function(sort_fn, 1)
    end

    test "handles empty order_sensitive_modifiers" do
      config = [order_sensitive_modifiers: []]
      sort_fn = SortModifiers.create_sort_modifiers(config)

      result = sort_fn.(["d", "c", "e"])
      assert result == ["c", "d", "e"]
    end

    test "handles missing order_sensitive_modifiers key" do
      config = []
      sort_fn = SortModifiers.create_sort_modifiers(config)

      result = sort_fn.(["d", "c", "e"])
      assert result == ["c", "d", "e"]
    end
  end

  describe "sort_modifiers/2" do
    setup do
      order_sensitive = MapSet.new(["hover", "focus", "active", "first", "last", "a", "b"])
      {:ok, order_sensitive: order_sensitive}
    end

    test "returns same list for empty input", %{order_sensitive: order_sensitive} do
      assert SortModifiers.sort_modifiers([], order_sensitive) == []
    end

    test "returns same list for single modifier", %{order_sensitive: order_sensitive} do
      assert SortModifiers.sort_modifiers(["c"], order_sensitive) == ["c"]
      assert SortModifiers.sort_modifiers(["hover"], order_sensitive) == ["hover"]
      assert SortModifiers.sort_modifiers(["[data-test]"], order_sensitive) == ["[data-test]"]
    end

    test "sorts regular modifiers alphabetically", %{order_sensitive: order_sensitive} do
      modifiers = ["e", "c", "d"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      assert result == ["c", "d", "e"]
    end

    test "preserves order when position-sensitive modifier encountered", %{
      order_sensitive: order_sensitive
    } do
      # Based on TypeScript logic: accumulate non-position-sensitive, sort them when position-sensitive encountered
      modifiers = ["d", "hover", "c"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      # "d" accumulated, "hover" encountered -> sort ["d"] and add "hover" -> ["d", "hover"]
      # "c" accumulated, end -> sort ["c"] and add -> ["d", "hover", "c"]
      assert result == ["d", "hover", "c"]
    end

    test "handles arbitrary variants (starting with [)", %{order_sensitive: order_sensitive} do
      modifiers = ["d", "[data-test]", "c"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      # "d" accumulated, "[data-test]" encountered -> sort ["d"] and add "[data-test]" -> ["d", "[data-test]"]
      # "c" accumulated, end -> sort ["c"] and add -> ["d", "[data-test]", "c"]
      assert result == ["d", "[data-test]", "c"]
    end

    test "complex sorting with mixed modifier types", %{order_sensitive: order_sensitive} do
      modifiers = ["e", "a", "d", "[custom]", "c", "b"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      # Expected behavior based on TypeScript algorithm:
      # 1. "e" -> unsorted = ["e"]
      # 2. "a" (position-sensitive) -> sorted = [] + ["e"] + ["a"] = ["e", "a"], unsorted = []
      # 3. "d" -> unsorted = ["d"]
      # 4. "[custom]" (arbitrary, position-sensitive) ->
      #    sorted = ["e", "a"] + ["d"] + ["[custom]"] = ["e", "a", "d", "[custom]"], unsorted = []
      # 5. "c" -> unsorted = ["c"]
      # 6. "b" (position-sensitive) ->
      #    sorted = ["e", "a", "d", "[custom]"] + ["c"] + ["b"] = ["e", "a", "d", "[custom]", "c", "b"], unsorted = []
      # 7. End -> no remaining unsorted

      expected = ["e", "a", "d", "[custom]", "c", "b"]
      assert result == expected
    end

    test "multiple regular modifiers before position-sensitive", %{
      order_sensitive: order_sensitive
    } do
      modifiers = ["e", "d", "c", "a"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      # "e", "d", "c" accumulated, "a" encountered ->
      # sort ["e", "d", "c"] = ["c", "d", "e"] and add "a"
      expected = ["c", "d", "e", "a"]
      assert result == expected
    end

    test "consecutive position-sensitive modifiers preserve order", %{
      order_sensitive: order_sensitive
    } do
      modifiers = ["c", "a", "b", "d"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      # "c" accumulated, "a" encountered -> ["c", "a"], "b" encountered -> ["c", "a", "b"],
      # "d" accumulated -> ["c", "a", "b", "d"]
      expected = ["c", "a", "b", "d"]
      assert result == expected
    end

    test "handles all position-sensitive modifiers", %{order_sensitive: order_sensitive} do
      modifiers = ["a", "b", "hover"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      assert result == ["a", "b", "hover"]
    end

    test "handles all regular modifiers", %{order_sensitive: order_sensitive} do
      modifiers = ["e", "c", "d"]
      result = SortModifiers.sort_modifiers(modifiers, order_sensitive)

      assert result == ["c", "d", "e"]
    end

    test "empty order sensitive modifiers treats all as regular" do
      empty_set = MapSet.new([])
      modifiers = ["e", "hover", "d", "focus", "c"]
      result = SortModifiers.sort_modifiers(modifiers, empty_set)

      # Only arbitrary variants (starting with [) are position-sensitive when no order_sensitive_modifiers
      assert result == ["c", "d", "e", "focus", "hover"]
    end

    test "arbitrary variants are always position-sensitive regardless of config" do
      empty_set = MapSet.new([])
      modifiers = ["d", "[data-test]", "c", "[custom-variant]", "e"]
      result = SortModifiers.sort_modifiers(modifiers, empty_set)

      # "d" accumulated, "[data-test]" encountered -> ["d", "[data-test]"]
      # "c" accumulated, "[custom-variant]" encountered -> ["d", "[data-test]", "c", "[custom-variant]"]
      # "e" accumulated, end -> ["d", "[data-test]", "c", "[custom-variant]", "e"]
      expected = ["d", "[data-test]", "c", "[custom-variant]", "e"]
      assert result == expected
    end
  end

  describe "integration with Tailwind modifier sorting examples" do
    test "sorts modifiers like in Tailwind tests" do
      # Based on the test: 'c:d:e:block d:c:e:inline' becomes 'd:c:e:inline'
      # This means modifiers ['c', 'd', 'e'] should become ['c', 'd', 'e'] (already sorted)
      # But modifiers ['d', 'c', 'e'] should become ['c', 'd', 'e']

      config = [order_sensitive_modifiers: []]
      sort_fn = SortModifiers.create_sort_modifiers(config)

      result1 = sort_fn.(["c", "d", "e"])
      assert result1 == ["c", "d", "e"]

      result2 = sort_fn.(["d", "c", "e"])
      assert result2 == ["c", "d", "e"]
    end

    test "preserves order with order-sensitive modifiers" do
      # Based on the test with orderSensitiveModifiers: ['a', 'b']
      # 'a:b:foo-1 b:a:foo-2' stays as separate classes because modifiers differ

      config = [order_sensitive_modifiers: ["a", "b"]]
      sort_fn = SortModifiers.create_sort_modifiers(config)

      # a:b should stay a:b
      result1 = sort_fn.(["a", "b"])
      assert result1 == ["a", "b"]

      # b:a should stay b:a (because both are order-sensitive)
      result2 = sort_fn.(["b", "a"])
      assert result2 == ["b", "a"]

      # Mix of order-sensitive and regular
      result3 = sort_fn.(["c", "a", "d"])
      # "c" sorted, then "a" position-sensitive, then "d"
      assert result3 == ["c", "a", "d"]
    end
  end
end
