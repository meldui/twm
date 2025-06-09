defmodule Twm.ArbitraryPropertiesTest do
  use ExUnit.Case, async: true

  describe "merge/1 with arbitrary properties" do
    test "handles arbitrary property conflicts correctly" do
      assert Twm.merge("[paint-order:markers] [paint-order:normal]") == "[paint-order:normal]"

      assert Twm.merge(
               "[paint-order:markers] [--my-var:2rem] [paint-order:normal] [--my-var:4px]"
             ) ==
               "[paint-order:normal] [--my-var:4px]"
    end

    test "handles arbitrary property conflicts with modifiers correctly" do
      assert Twm.merge("[paint-order:markers] hover:[paint-order:normal]") ==
               "[paint-order:markers] hover:[paint-order:normal]"

      assert Twm.merge("hover:[paint-order:markers] hover:[paint-order:normal]") ==
               "hover:[paint-order:normal]"

      assert Twm.merge("hover:focus:[paint-order:markers] focus:hover:[paint-order:normal]") ==
               "focus:hover:[paint-order:normal]"

      assert Twm.merge(
               "[paint-order:markers] [paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]"
             ) ==
               "[paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]"

      assert Twm.merge("[background:red] [background:blue] [border:solid]") ==
               "[background:blue] [border:solid]"
    end

    test "handles complex arbitrary property conflicts correctly" do
      assert Twm.merge("[-unknown-prop:::123:::] [-unknown-prop:url(https://hi.com)]") ==
               "[-unknown-prop:url(https://hi.com)]"
    end

    test "handles important modifier correctly" do
      assert Twm.merge("![some:prop] [some:other]") == "![some:prop] [some:other]"

      assert Twm.merge("![some:prop] [some:other] [some:one] ![some:another]") ==
               "[some:one] ![some:another]"
    end
  end

  describe "merge/1 with custom configuration" do
    test "handles arbitrary properties with custom config" do
      # Test with custom configuration that allows configuration override
      custom_config = %{
        cache_name: Twm.Cache,
        cache_size: 100,
        theme: %{},
        class_groups: %{
          "arbitrary-property" => [
            %{
              "arbitrary-property" => &Twm.is_arbitrary_value/1
            }
          ]
        },
        conflicting_class_groups: %{
          "arbitrary-property" => ["arbitrary-property"]
        },
        conflicting_class_group_modifiers: %{},
        order_sensitive_modifiers: []
      }

      # Create a custom merge function with the configuration
      custom_merge = Twm.create_tailwind_merge(fn -> custom_config end)

      # Test that the custom merge function handles arbitrary properties
      assert custom_merge.("[paint-order:markers] [paint-order:normal]") ==
               "[paint-order:normal]"
    end

    test "handles arbitrary properties with extended configuration" do
      # Test extending the default configuration
      extended_config =
        Twm.Config.extend(
          cache_size: 200,
          extend: %{
            class_groups: %{
              "custom-arbitrary" => [
                %{
                  "custom-arbitrary" => &Twm.is_arbitrary_value/1
                }
              ]
            }
          }
        )

      # Create a custom merge function with extended configuration  
      custom_merge = Twm.create_tailwind_merge(fn -> extended_config end)

      # Test basic functionality still works
      assert custom_merge.("[paint-order:markers] [paint-order:normal]") ==
               "[paint-order:normal]"
    end

    test "handles arbitrary properties with override configuration" do
      # Test overriding parts of the default configuration
      overridden_config =
        Twm.Config.extend(
          override: %{
            cache_size: 50
          },
          extend: %{
            class_groups: %{
              "test-arbitrary" => [
                %{
                  "test-arbitrary" => &Twm.is_arbitrary_value/1
                }
              ]
            }
          }
        )

      # Create a custom merge function with overridden configuration
      custom_merge = Twm.create_tailwind_merge(fn -> overridden_config end)

      # Test that arbitrary properties still work with overridden config
      assert custom_merge.("![some:prop] [some:other]") == "![some:prop] [some:other]"

      assert custom_merge.("![some:prop] [some:other] [some:one] ![some:another]") ==
               "[some:one] ![some:another]"
    end
  end

  describe "tw_merge/1 with arbitrary properties" do
    test "tw_merge is an alias that handles arbitrary properties" do
      assert Twm.tw_merge("[paint-order:markers] [paint-order:normal]") ==
               Twm.merge("[paint-order:markers] [paint-order:normal]")

      assert Twm.tw_merge("hover:[paint-order:markers] hover:[paint-order:normal]") ==
               Twm.merge("hover:[paint-order:markers] hover:[paint-order:normal]")

      assert Twm.tw_merge("![some:prop] [some:other]") ==
               Twm.merge("![some:prop] [some:other]")
    end
  end

  describe "merge/1 with list input and arbitrary properties" do
    test "handles arbitrary properties when classes are provided as a list" do
      assert Twm.merge(["[paint-order:markers]", "[paint-order:normal]"]) ==
               "[paint-order:normal]"

      assert Twm.merge(["hover:[paint-order:markers]", "hover:[paint-order:normal]"]) ==
               "hover:[paint-order:normal]"

      assert Twm.merge(["![some:prop]", "[some:other]", "[some:one]", "![some:another]"]) ==
               "[some:one] ![some:another]"
    end
  end

  describe "edge cases with arbitrary properties" do
    test "handles empty arbitrary properties" do
      assert Twm.merge("[] [paint-order:normal]") == "[] [paint-order:normal]"
    end

    test "handles arbitrary properties with CSS variables" do
      assert Twm.merge("[--custom:value1] [--custom:value2]") == "[--custom:value2]"
      assert Twm.merge("[--my-var:2rem] [--my-var:4px]") == "[--my-var:4px]"
    end

    test "handles malformed arbitrary properties" do
      assert Twm.merge("[paint-order [paint-order:normal]") == "[paint-order [paint-order:normal]"

      assert Twm.merge("paint-order:] [paint-order:normal]") ==
               "paint-order:] [paint-order:normal]"
    end

    test "handles mixed arbitrary and regular properties" do
      assert Twm.merge(
               "[background:red] [paint-order:markers] [background:blue] [paint-order:normal]"
             ) ==
               "[background:blue] [paint-order:normal]"
    end

    test "handles multiple modifiers with arbitrary properties" do
      assert Twm.merge("sm:hover:focus:[paint-order:markers] sm:hover:focus:[paint-order:normal]") ==
               "sm:hover:focus:[paint-order:normal]"
    end

    test "handles arbitrary properties with special characters" do
      assert Twm.merge("[--custom-var:calc(100%-2rem)] [--custom-var:calc(50%+1rem)]") ==
               "[--custom-var:calc(50%+1rem)]"
    end
  end
end
