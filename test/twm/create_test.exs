defmodule Twm.Config.CreateTest do
  use ExUnit.Case, async: true

  describe "Tailwind.merge/2" do
    test "works with single config function" do
      config =
        Twm.Config.new(
          cache_name: Twm.Cache,
          cache_size: 20,
          theme: [],
          class_groups: [
            fooKey: [%{fooKey: ["bar", "baz"]}],
            fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
            otherKey: ["nother", "group"]
          ],
          conflicting_class_groups: [
            fooKey: ["otherKey"],
            otherKey: ["fooKey", "fooKey2"]
          ],
          conflicting_class_group_modifiers: [],
          order_sensitive_modifiers: []
        )

      assert Twm.merge("", config) == ""

      assert Twm.merge("my-modifier:fooKey-bar my-modifier:fooKey-baz", config) ==
               "my-modifier:fooKey-baz"

      assert Twm.merge("other-modifier:fooKey-bar other-modifier:fooKey-baz", config) ==
               "other-modifier:fooKey-baz"

      assert Twm.merge("group fooKey-bar", config) == "fooKey-bar"
      assert Twm.merge("fooKey-bar group", config) == "group"
      assert Twm.merge("group other-2", config) == "group other-2"
      assert Twm.merge("other-2 group", config) == "group"
    end

    test "works with multiple config functions" do
      config =
        Twm.Config.new(
          cache_name: Twm.Cache,
          cache_size: 20,
          theme: [],
          class_groups: [
            fooKey: [%{fooKey: ["bar", "baz"]}],
            fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
            otherKey: ["nother", "group"]
          ],
          conflicting_class_groups: [
            fooKey: ["otherKey"],
            otherKey: ["fooKey", "fooKey2"]
          ],
          conflicting_class_group_modifiers: [],
          order_sensitive_modifiers: []
        )

      config =
        Twm.Config.extend(config, fn config ->
          # Update class_groups
          config =
            Map.update!(config, :class_groups, fn class_groups ->
              Keyword.put(class_groups, :helloFromSecondConfig, ["hello-there"])
            end)

          # Update conflicting_class_groups
          Map.update!(config, :conflicting_class_groups, fn conflicting ->
            Keyword.update(conflicting, :fooKey, ["helloFromSecondConfig"], fn existing ->
              existing ++ ["helloFromSecondConfig"]
            end)
          end)
        end)

      assert Twm.merge("", config) == ""

      assert Twm.merge("my-modifier:fooKey-bar my-modifier:fooKey-baz", config) ==
               "my-modifier:fooKey-baz"

      assert Twm.merge("other-modifier:fooKey-bar other-modifier:fooKey-baz", config) ==
               "other-modifier:fooKey-baz"

      assert Twm.merge("group fooKey-bar", config) == "fooKey-bar"
      assert Twm.merge("fooKey-bar group", config) == "group"
      assert Twm.merge("group other-2", config) == "group other-2"
      assert Twm.merge("other-2 group", config) == "group"

      assert Twm.merge("second:group second:nother", config) == "second:nother"
      assert Twm.merge("fooKey-bar hello-there", config) == "fooKey-bar hello-there"
      assert Twm.merge("hello-there fooKey-bar", config) == "fooKey-bar"
    end
  end
end
