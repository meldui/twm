defmodule Twm.Config.CreateTest do
  alias Twm.Cache
  use ExUnit.Case, async: true
  doctest Twm.Config.Create

  describe "tailwind_merge/1" do
    test "works with single config function" do
      tailwind_merge =
        Twm.create_tailwind_merge(fn ->
          %{
            cache_name: Twm.Cache,
            cache_size: 20,
            theme: %{},
            class_groups: %{
              fooKey: [%{fooKey: ["bar", "baz"]}],
              fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
              otherKey: ["nother", "group"]
            },
            conflicting_class_groups: %{
              fooKey: ["otherKey"],
              otherKey: ["fooKey", "fooKey2"]
            },
            conflicting_class_group_modifiers: %{},
            order_sensitive_modifiers: []
          }
        end)

      assert tailwind_merge.("") == ""

      assert tailwind_merge.("my-modifier:fooKey-bar my-modifier:fooKey-baz") ==
               "my-modifier:fooKey-baz"

      assert tailwind_merge.("other-modifier:fooKey-bar other-modifier:fooKey-baz") ==
               "other-modifier:fooKey-baz"

      assert tailwind_merge.("group fooKey-bar") == "fooKey-bar"
      assert tailwind_merge.("fooKey-bar group") == "group"
      assert tailwind_merge.("group other-2") == "group other-2"
      assert tailwind_merge.("other-2 group") == "group"
    end

    test "works with multiple config functions" do
      tailwind_merge =
        Twm.create_tailwind_merge([
          fn ->
            %{
              cache_name: Twm.Cache,
              cache_size: 20,
              theme: %{},
              class_groups: %{
                fooKey: [%{fooKey: ["bar", "baz"]}],
                fooKey2: [%{fooKey: ["qux", "quux"]}, "other-2"],
                otherKey: ["nother", "group"]
              },
              conflicting_class_groups: %{
                fooKey: ["otherKey"],
                otherKey: ["fooKey", "fooKey2"]
              },
              conflicting_class_group_modifiers: %{},
              order_sensitive_modifiers: []
            }
          end,
          fn config ->
            # Update class_groups
            config =
              Map.update!(config, :class_groups, fn class_groups ->
                Map.put(class_groups, :helloFromSecondConfig, ["hello-there"])
              end)

            # Update conflicting_class_groups
            Map.update!(config, :conflicting_class_groups, fn conflicting ->
              Map.update(conflicting, :fooKey, ["helloFromSecondConfig"], fn existing ->
                existing ++ ["helloFromSecondConfig"]
              end)
            end)
          end
        ])

      assert tailwind_merge.("") == ""

      assert tailwind_merge.("my-modifier:fooKey-bar my-modifier:fooKey-baz") ==
               "my-modifier:fooKey-baz"

      assert tailwind_merge.("other-modifier:fooKey-bar other-modifier:fooKey-baz") ==
               "other-modifier:fooKey-baz"

      assert tailwind_merge.("group fooKey-bar") == "fooKey-bar"
      assert tailwind_merge.("fooKey-bar group") == "group"
      assert tailwind_merge.("group other-2") == "group other-2"
      assert tailwind_merge.("other-2 group") == "group"

      assert tailwind_merge.("second:group second:nother") == "second:nother"
      assert tailwind_merge.("fooKey-bar hello-there") == "fooKey-bar hello-there"
      assert tailwind_merge.("hello-there fooKey-bar") == "fooKey-bar"
    end
  end
end
