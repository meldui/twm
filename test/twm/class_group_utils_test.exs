defmodule Twm.ClassGroupUtilsTest do
  use ExUnit.Case, async: true
  doctest Twm.ClassGroupUtils

  alias Twm.ClassGroupUtils

  describe "create_class_group_utils/1" do
    test "returns a map with required functions" do
      config = %Twm.Config{
        class_groups: [],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert %Twm.Context.ClassGroupProcessingContext{} = context
      assert is_list(context.class_map)
      assert is_list(context.conflicting_class_groups)
      assert is_list(context.conflicting_class_group_modifiers)
    end

    test "get_class_group_id function works with simple classes" do
      config = %Twm.Config{
        class_groups: [
          display: ["block", "inline", "flex"],
          position: ["static", "relative", "absolute"]
        ],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("block", context) == "display"
      assert ClassGroupUtils.get_class_group_id("inline", context) == "display"
      assert ClassGroupUtils.get_class_group_id("flex", context) == "display"
      assert ClassGroupUtils.get_class_group_id("static", context) == "position"
      assert ClassGroupUtils.get_class_group_id("relative", context) == "position"
      assert ClassGroupUtils.get_class_group_id("unknown", context) == nil
    end

    test "get_conflicting_class_group_ids function works" do
      config =
        Twm.Config.new(
          cache_size: 10,
          class_groups: [],
          conflicting_class_groups: [
            position: ["display", "float"],
            display: ["position"]
          ],
          conflicting_class_group_modifiers: [
            font_size: ["leading"]
          ],
          theme: []
        )

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_conflicting_class_group_ids("display", false, context) == [
               "position"
             ]

      assert ClassGroupUtils.get_conflicting_class_group_ids("position", false, context) == [
               "display",
               "float"
             ]

      assert ClassGroupUtils.get_conflicting_class_group_ids("font_size", true, context) == [
               "leading"
             ]

      assert ClassGroupUtils.get_conflicting_class_group_ids("font_size", false, context) == []
      assert ClassGroupUtils.get_conflicting_class_group_ids("unknown", false, context) == []
    end
  end

  describe "create_class_map/1" do
    test "returns a map with proper structure" do
      config =
        Twm.Config.new(
          cache_size: 10,
          class_groups: [
            display: ["block", "inline"]
          ],
          theme: []
        )

      class_map = ClassGroupUtils.create_class_map(config)

      assert Keyword.has_key?(class_map, :next_part)
      assert Keyword.has_key?(class_map, :validators)
      assert Keyword.has_key?(class_map, :class_group_id)
    end

    test "handles simple string classes" do
      config = %Twm.Config{
        class_groups: [
          display: ["block", "inline"]
        ],
        theme: []
      }

      class_map = ClassGroupUtils.create_class_map(config)

      next_part = Keyword.get(class_map, :next_part, [])
      block_part = Keyword.get(next_part, :block, [])
      inline_part = Keyword.get(next_part, :inline, [])
      assert Keyword.get(block_part, :class_group_id) == "display"
      assert Keyword.get(inline_part, :class_group_id) == "display"
    end

    test "handles hyphenated classes" do
      config = %Twm.Config{
        class_groups: [
          spacing: ["space-x-1", "space-y-2"]
        ],
        theme: []
      }

      class_map = ClassGroupUtils.create_class_map(config)

      next_part = Keyword.get(class_map, :next_part, [])
      space_part = Keyword.get(next_part, :space, [])
      space_next_part = Keyword.get(space_part, :next_part, [])
      x_part = Keyword.get(space_next_part, :x, [])
      x_next_part = Keyword.get(x_part, :next_part, [])
      one_part = Keyword.get(x_next_part, :"1", [])
      assert Keyword.get(one_part, :class_group_id) == "spacing"

      y_part = Keyword.get(space_next_part, :y, [])
      y_next_part = Keyword.get(y_part, :next_part, [])
      two_part = Keyword.get(y_next_part, :"2", [])
      assert Keyword.get(two_part, :class_group_id) == "spacing"
    end

    test "handles nested object classes" do
      config = %Twm.Config{
        class_groups: [
          spacing: [
            %{
              "p" => ["1", "2", "3"],
              "m" => ["1", "2"]
            }
          ]
        ],
        theme: []
      }

      class_map = ClassGroupUtils.create_class_map(config)

      next_part = Keyword.get(class_map, :next_part, [])
      p_part = Keyword.get(next_part, :p, [])
      p_next_part = Keyword.get(p_part, :next_part, [])
      p1_part = Keyword.get(p_next_part, :"1", [])
      p2_part = Keyword.get(p_next_part, :"2", [])
      assert Keyword.get(p1_part, :class_group_id) == "spacing"
      assert Keyword.get(p2_part, :class_group_id) == "spacing"

      m_part = Keyword.get(next_part, :m, [])
      m_next_part = Keyword.get(m_part, :next_part, [])
      m1_part = Keyword.get(m_next_part, :"1", [])
      assert Keyword.get(m1_part, :class_group_id) == "spacing"
    end

    test "handles function validators" do
      is_integer = fn value ->
        String.match?(value, ~r/^\d+$/)
      end

      config = %Twm.Config{
        class_groups: [
          spacing: [is_integer]
        ],
        theme: []
      }

      class_map = ClassGroupUtils.create_class_map(config)

      validators = Keyword.get(class_map, :validators, [])
      assert length(validators) == 1
      first_validator = List.first(validators)
      assert Keyword.get(first_validator, :class_group_id) == "spacing"
      assert is_function(Keyword.get(first_validator, :validator))
    end

    test "handles empty class definitions" do
      config = %Twm.Config{
        class_groups: [
          container: [""]
        ],
        theme: []
      }

      class_map = ClassGroupUtils.create_class_map(config)

      assert Keyword.get(class_map, :class_group_id) == "container"
    end
  end

  describe "class group identification" do
    setup do
      is_color = fn value -> String.ends_with?(value, "-500") end

      config = %Twm.Config{
        class_groups: [
          display: ["block", "inline", "flex", "grid"],
          colors: [is_color],
          spacing: ["p-1", "p-2", "m-1", "m-2"],
          layout: [
            %{
              "h" => ["full", "screen"],
              "w" => ["full", "1/2", "1/3"]
            }
          ]
        ],
        conflicting_class_groups: [
          display: ["spacing"],
          spacing: ["display"]
        ],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)
      {:ok, context: context}
    end

    test "identifies simple classes", %{context: context} do
      assert ClassGroupUtils.get_class_group_id("block", context) == "display"
      assert ClassGroupUtils.get_class_group_id("inline", context) == "display"
      assert ClassGroupUtils.get_class_group_id("grid", context) == "display"
    end

    test "identifies hyphenated classes", %{context: context} do
      assert ClassGroupUtils.get_class_group_id("p-1", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("p-2", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("m-1", context) == "spacing"
    end

    test "identifies nested classes", %{context: context} do
      assert ClassGroupUtils.get_class_group_id("w-full", context) == "layout"
      assert ClassGroupUtils.get_class_group_id("h-screen", context) == "layout"
      assert ClassGroupUtils.get_class_group_id("h-full", context) == "layout"
      assert ClassGroupUtils.get_class_group_id("w-1/2", context) == "layout"
    end

    test "identifies classes via validators", %{context: context} do
      assert ClassGroupUtils.get_class_group_id("bg-red-500", context) == "colors"
      assert ClassGroupUtils.get_class_group_id("text-blue-500", context) == "colors"
      assert ClassGroupUtils.get_class_group_id("border-green-500", context) == "colors"
    end

    test "returns nil for unmatched classes", %{context: context} do
      assert ClassGroupUtils.get_class_group_id("unknown-class", context) == nil
      assert ClassGroupUtils.get_class_group_id("random", context) == nil
      # Doesn't end with -500
      assert ClassGroupUtils.get_class_group_id("bg-blue-400", context) == nil
    end

    test "handles negative classes" do
      # Simulate negative spacing class
      config = %Twm.Config{
        class_groups: [
          spacing: ["-m-1", "-p-1"]
        ],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      # context = ClassGroupUtils.create_class_group_utils(config |> Twm.Config.update_class_map())
      context = ClassGroupUtils.create_class_group_utils(config)
      assert ClassGroupUtils.get_class_group_id("-m-1", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("-p-1", context) == "spacing"
    end
  end

  describe "arbitrary properties" do
    test "identifies arbitrary properties" do
      config = %Twm.Config{
        class_groups: [],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("[color:red]", context) == "arbitrary..color"

      assert ClassGroupUtils.get_class_group_id("[font-size:14px]", context) ==
               "arbitrary..font-size"
    end

    test "ignores malformed arbitrary properties" do
      config = %Twm.Config{
        class_groups: [],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("[invalid]", context) == nil
      assert ClassGroupUtils.get_class_group_id("[no-colon]", context) == nil
      assert ClassGroupUtils.get_class_group_id("not-brackets", context) == nil
    end
  end

  describe "conflicting class groups" do
    test "returns conflicts without postfix modifier" do
      config = %Twm.Config{
        class_groups: [],
        conflicting_class_groups: [
          position: ["display"],
          display: ["position", "float"]
        ],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_conflicting_class_group_ids("display", false, context) == [
               "position",
               "float"
             ]

      assert ClassGroupUtils.get_conflicting_class_group_ids("position", false, context) == [
               "display"
             ]
    end

    test "returns conflicts with postfix modifier" do
      config = %Twm.Config{
        class_groups: [],
        conflicting_class_groups: [
          font_size: ["leading"]
        ],
        conflicting_class_group_modifiers: [
          font_size: ["line_height"]
        ],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_conflicting_class_group_ids("font_size", false, context) == [
               "leading"
             ]

      assert ClassGroupUtils.get_conflicting_class_group_ids("font_size", true, context) == [
               "leading",
               "line_height"
             ]
    end

    test "handles missing conflict groups" do
      config = %Twm.Config{
        class_groups: [],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_conflicting_class_group_ids("unknown", false, context) == []
      assert ClassGroupUtils.get_conflicting_class_group_ids("unknown", true, context) == []
    end
  end

  describe "complex scenarios" do
    test "handles mixed class definitions" do
      is_number = fn value ->
        String.match?(value, ~r/^\d+$/)
      end

      config = %Twm.Config{
        class_groups: [
          spacing: [
            "auto",
            is_number,
            %{
              "p" => ["1", "2", is_number],
              "m" => ["auto", is_number]
            }
          ]
        ],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("auto", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("p-1", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("m-auto", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("p-2", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("p-42", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("42", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("m-42", context) == "spacing"
    end

    test "validates with multiple validators" do
      is_number = fn value ->
        String.match?(value, ~r/^\d+$/)
      end

      is_fraction = fn value ->
        String.match?(value, ~r/^\d+\/\d+$/)
      end

      config = %Twm.Config{
        class_groups: [
          width: [is_number, is_fraction, "full", "auto"]
        ],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("42", context) == "width"
      assert ClassGroupUtils.get_class_group_id("1/2", context) == "width"
      assert ClassGroupUtils.get_class_group_id("full", context) == "width"
      assert ClassGroupUtils.get_class_group_id("auto", context) == "width"
      assert ClassGroupUtils.get_class_group_id("invalid", context) == nil
    end
  end

  describe "edge cases" do
    test "handles empty class groups" do
      config =
        Twm.Config.new(
          cache_size: 10,
          class_groups: [],
          conflicting_class_groups: [],
          conflicting_class_group_modifiers: [],
          theme: [],
          class_map: []
        )

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("block", context) == nil
    end

    test "handles missing config keys" do
      config = Twm.Config.new([])

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("block", context) == nil
      assert ClassGroupUtils.get_conflicting_class_group_ids("display", false, context) == []
    end

    test "handles deeply nested classes" do
      config = %Twm.Config{
        class_groups: [
          complex: [
            %{
              "level1" => %{
                "level2" => %{
                  "level3" => ["deep"]
                }
              }
            }
          ]
        ],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("level1-level2-level3-deep", context) == "complex"
    end

    test "handles class names with multiple hyphens" do
      config = %Twm.Config{
        class_groups: [
          spacing: ["space-x-reverse", "space-y-reverse"]
        ],
        conflicting_class_groups: [],
        conflicting_class_group_modifiers: [],
        theme: []
      }

      context = ClassGroupUtils.create_class_group_utils(config)

      assert ClassGroupUtils.get_class_group_id("space-x-reverse", context) == "spacing"
      assert ClassGroupUtils.get_class_group_id("space-y-reverse", context) == "spacing"
    end
  end
end
