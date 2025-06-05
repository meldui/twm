defmodule Twm.DefaultConfigTest do
  use ExUnit.Case, async: true
  alias Twm.Config
  alias Twm.Config.Default

  describe "default_config" do
    test "has correct structure and values" do
      default_config = Default.get()

      # Check static configuration values
      assert default_config.cache_size == 500
      assert is_map(default_config.theme)
      assert is_map(default_config.class_groups)
      assert is_map(default_config.conflicting_class_groups)
      assert is_map(default_config.conflicting_class_group_modifiers)
      assert is_list(default_config.order_sensitive_modifiers)

      # Test specific class groups from the default config
      assert "block" in default_config.class_groups.display

      # Test conflicting class groups
      assert is_list(default_config.conflicting_class_groups.inset)
      assert "inset_x" in default_config.conflicting_class_groups.inset
      assert "inset_y" in default_config.conflicting_class_groups.inset
    end

    test "can be extended with custom options" do
      # Test overriding cache_size
      config = Config.extend(cache_size: 1000)
      assert config.cache_size == 1000

      # Test extending class groups
      config =
        Config.extend(
          extend: %{
            class_groups: %{
              custom_group: ["custom-value"]
            }
          }
        )

      assert config.cache_size == 500
      assert config.class_groups.custom_group == ["custom-value"]
      assert "block" in config.class_groups.display

      # Test overriding class groups
      config =
        Config.extend(
          override: %{
            class_groups: %{
              display: ["custom-display"]
            }
          }
        )

      assert config.class_groups.display == ["custom-display"]
    end

    test "can be validated" do
      # Valid config
      assert {:ok, _} = Config.validate(Default.get())

      # Invalid config (missing required keys)
      assert {:error, message} = Config.validate(%{})
      assert String.contains?(message, "Missing required configuration keys")
    end
  end

  describe "theme" do
    test "has all required theme scales" do
      theme = Default.get().theme

      theme_keys = [
        :color,
        :font,
        :text,
        :font_weight,
        :tracking,
        :leading,
        :breakpoint,
        :container,
        :spacing,
        :radius,
        :shadow,
        :inset_shadow,
        :text_shadow,
        :drop_shadow,
        :blur,
        :perspective,
        :aspect,
        :ease,
        :animate
      ]

      for key <- theme_keys do
        assert Map.has_key?(theme, key)
      end
    end
  end
end
