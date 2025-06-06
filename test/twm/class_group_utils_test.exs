defmodule Twm.ClassGroupUtilsTest do
  use ExUnit.Case, async: true
  doctest Twm.ClassGroupUtils

  alias Twm.ClassGroupUtils

  describe "create_class_group_utils/1" do
    test "returns a map with required functions" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert is_function(utils.get_class_group_id, 1)
      assert is_function(utils.get_conflicting_class_group_ids, 2)
    end

    test "get_class_group_id function works with simple classes" do
      config = %{
        class_groups: %{
          display: ["block", "inline", "flex"],
          position: ["static", "relative", "absolute"]
        },
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("block") == "display"
      assert utils.get_class_group_id.("inline") == "display"
      assert utils.get_class_group_id.("flex") == "display"
      assert utils.get_class_group_id.("static") == "position"
      assert utils.get_class_group_id.("relative") == "position"
      assert utils.get_class_group_id.("unknown") == nil
    end

    test "get_conflicting_class_group_ids function works" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{
          display: ["position"],
          position: ["display", "float"]
        },
        conflicting_class_group_modifiers: %{
          font_size: ["leading"]
        },
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_conflicting_class_group_ids.("display", false) == ["position"]
      assert utils.get_conflicting_class_group_ids.("position", false) == ["display", "float"]
      assert utils.get_conflicting_class_group_ids.("font_size", true) == ["leading"]
      assert utils.get_conflicting_class_group_ids.("font_size", false) == []
      assert utils.get_conflicting_class_group_ids.("unknown", false) == []
    end
  end

  describe "create_class_map/1" do
    test "creates basic class map structure" do
      config = %{
        class_groups: %{
          display: ["block", "inline"]
        },
        theme: %{}
      }

      class_map = ClassGroupUtils.create_class_map(config)

      assert Map.has_key?(class_map, :next_part)
      assert Map.has_key?(class_map, :validators)
      assert Map.has_key?(class_map, :class_group_id)
    end

    test "handles simple string classes" do
      config = %{
        class_groups: %{
          display: ["block", "inline"]
        },
        theme: %{}
      }

      class_map = ClassGroupUtils.create_class_map(config)

      assert get_in(class_map, [:next_part, "block", :class_group_id]) == "display"
      assert get_in(class_map, [:next_part, "inline", :class_group_id]) == "display"
    end

    test "handles hyphenated classes" do
      config = %{
        class_groups: %{
          spacing: ["space-x-1", "space-y-2"]
        },
        theme: %{}
      }

      class_map = ClassGroupUtils.create_class_map(config)

      assert get_in(class_map, [
               :next_part,
               "space",
               :next_part,
               "x",
               :next_part,
               "1",
               :class_group_id
             ]) == "spacing"

      assert get_in(class_map, [
               :next_part,
               "space",
               :next_part,
               "y",
               :next_part,
               "2",
               :class_group_id
             ]) == "spacing"
    end

    test "handles nested object classes" do
      config = %{
        class_groups: %{
          spacing: [
            %{
              "p" => ["1", "2", "3"],
              "m" => ["1", "2"]
            }
          ]
        },
        theme: %{}
      }

      class_map = ClassGroupUtils.create_class_map(config)

      assert get_in(class_map, [:next_part, "p", :next_part, "1", :class_group_id]) == "spacing"
      assert get_in(class_map, [:next_part, "p", :next_part, "2", :class_group_id]) == "spacing"
      assert get_in(class_map, [:next_part, "m", :next_part, "1", :class_group_id]) == "spacing"
    end

    test "handles function validators" do
      is_integer = fn value ->
        String.match?(value, ~r/^\d+$/)
      end

      config = %{
        class_groups: %{
          spacing: [is_integer]
        },
        theme: %{}
      }

      class_map = ClassGroupUtils.create_class_map(config)

      validators = Map.get(class_map, :validators, [])
      assert length(validators) == 1
      assert List.first(validators).class_group_id == "spacing"
      assert is_function(List.first(validators).validator)
    end

    test "handles empty class definitions" do
      config = %{
        class_groups: %{
          container: [""]
        },
        theme: %{}
      }

      class_map = ClassGroupUtils.create_class_map(config)

      assert class_map.class_group_id == "container"
    end
  end

  describe "class group identification" do
    setup do
      config = %{
        class_groups: %{
          display: ["block", "inline", "flex", "grid"],
          spacing: ["p-1", "p-2", "m-1", "m-2"],
          colors: [fn value -> String.ends_with?(value, "-500") end],
          layout: [
            %{
              "w" => ["full", "1/2", "1/3"],
              "h" => ["full", "screen"]
            }
          ]
        },
        conflicting_class_groups: %{
          display: ["spacing"],
          spacing: ["display"]
        },
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)
      {:ok, utils: utils}
    end

    test "identifies simple classes", %{utils: utils} do
      assert utils.get_class_group_id.("block") == "display"
      assert utils.get_class_group_id.("flex") == "display"
      assert utils.get_class_group_id.("grid") == "display"
    end

    test "identifies hyphenated classes", %{utils: utils} do
      assert utils.get_class_group_id.("p-1") == "spacing"
      assert utils.get_class_group_id.("p-2") == "spacing"
      assert utils.get_class_group_id.("m-1") == "spacing"
    end

    test "identifies nested classes", %{utils: utils} do
      assert utils.get_class_group_id.("w-full") == "layout"
      assert utils.get_class_group_id.("w-1/2") == "layout"
      assert utils.get_class_group_id.("h-full") == "layout"
      assert utils.get_class_group_id.("h-screen") == "layout"
    end

    test "identifies classes via validators", %{utils: utils} do
      assert utils.get_class_group_id.("bg-blue-500") == "colors"
      assert utils.get_class_group_id.("text-red-500") == "colors"
      assert utils.get_class_group_id.("border-green-500") == "colors"
    end

    test "returns nil for unknown classes", %{utils: utils} do
      assert utils.get_class_group_id.("unknown") == nil
      assert utils.get_class_group_id.("not-a-class") == nil
      # Doesn't end with -500
      assert utils.get_class_group_id.("bg-blue-400") == nil
    end

    test "handles negative classes" do
      # Simulate negative spacing class
      config = %{
        class_groups: %{
          spacing: ["-m-1", "-p-1"]
        },
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)
      assert utils.get_class_group_id.("-m-1") == "spacing"
      assert utils.get_class_group_id.("-p-1") == "spacing"
    end
  end

  describe "arbitrary properties" do
    test "identifies arbitrary properties" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("[color:red]") == "arbitrary..color"
      assert utils.get_class_group_id.("[background-color:blue]") == "arbitrary..background-color"
      assert utils.get_class_group_id.("[font-size:16px]") == "arbitrary..font-size"
    end

    test "ignores malformed arbitrary properties" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("[invalid]") == nil
      assert utils.get_class_group_id.("[no-colon]") == nil
      assert utils.get_class_group_id.("not-brackets") == nil
    end
  end

  describe "conflicting class groups" do
    test "returns conflicts without postfix modifier" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{
          display: ["position", "float"],
          position: ["display"]
        },
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_conflicting_class_group_ids.("display", false) == ["position", "float"]
      assert utils.get_conflicting_class_group_ids.("position", false) == ["display"]
    end

    test "returns conflicts with postfix modifier" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{
          font_size: ["leading"]
        },
        conflicting_class_group_modifiers: %{
          font_size: ["line_height"]
        },
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_conflicting_class_group_ids.("font_size", false) == ["leading"]

      assert utils.get_conflicting_class_group_ids.("font_size", true) == [
               "leading",
               "line_height"
             ]
    end

    test "handles missing conflict groups" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_conflicting_class_group_ids.("unknown", false) == []
      assert utils.get_conflicting_class_group_ids.("unknown", true) == []
    end
  end

  describe "complex scenarios" do
    test "handles mixed class definitions" do
      is_number = fn value ->
        String.match?(value, ~r/^\d+$/)
      end

      config = %{
        class_groups: %{
          spacing: [
            "auto",
            is_number,
            %{
              "p" => ["1", "2", is_number],
              "m" => ["auto", is_number]
            }
          ]
        },
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("auto") == "spacing"
      assert utils.get_class_group_id.("42") == "spacing"
      assert utils.get_class_group_id.("p-1") == "spacing"
      assert utils.get_class_group_id.("p-2") == "spacing"
      assert utils.get_class_group_id.("p-42") == "spacing"
      assert utils.get_class_group_id.("m-auto") == "spacing"
      assert utils.get_class_group_id.("m-42") == "spacing"
    end

    test "validates with multiple validators" do
      is_number = fn value ->
        String.match?(value, ~r/^\d+$/)
      end

      is_fraction = fn value ->
        String.match?(value, ~r/^\d+\/\d+$/)
      end

      config = %{
        class_groups: %{
          width: [is_number, is_fraction, "full", "auto"]
        },
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("42") == "width"
      assert utils.get_class_group_id.("1/2") == "width"
      assert utils.get_class_group_id.("full") == "width"
      assert utils.get_class_group_id.("auto") == "width"
      assert utils.get_class_group_id.("invalid") == nil
    end
  end

  describe "edge cases" do
    test "handles empty class groups" do
      config = %{
        class_groups: %{},
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("anything") == nil
    end

    test "handles missing config keys" do
      config = %{}

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("block") == nil
      assert utils.get_conflicting_class_group_ids.("display", false) == []
    end

    test "handles deeply nested classes" do
      config = %{
        class_groups: %{
          complex: [
            %{
              "level1" => %{
                "level2" => %{
                  "level3" => ["deep"]
                }
              }
            }
          ]
        },
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("level1-level2-level3-deep") == "complex"
    end

    test "handles class names with multiple hyphens" do
      config = %{
        class_groups: %{
          spacing: ["space-x-reverse", "space-y-reverse"]
        },
        conflicting_class_groups: %{},
        conflicting_class_group_modifiers: %{},
        theme: %{}
      }

      utils = ClassGroupUtils.create_class_group_utils(config)

      assert utils.get_class_group_id.("space-x-reverse") == "spacing"
      assert utils.get_class_group_id.("space-y-reverse") == "spacing"
    end
  end
end
