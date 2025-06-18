defmodule Twm.ThemeTest do
  use ExUnit.Case, async: false

  alias Twm.Config.Theme

  describe "theme scale extension" do
    test "theme scale can be extended" do
      custom_merge =
        Twm.extend_tailwind_merge(
          extend: [
            theme: [
              spacing: ["my-space"],
              leading: ["my-leading"]
            ]
          ]
        )

      assert custom_merge.("p-3 p-my-space p-my-margin") == "p-my-space p-my-margin"

      assert custom_merge.("leading-3 leading-my-space leading-my-leading") ==
               "leading-my-leading"
    end
  end

  describe "theme object extension" do
    test "theme object can be extended" do
      custom_merge =
        Twm.extend_tailwind_merge(
          extend: [
            theme: [
              "my-theme": ["hallo", "hello"]
            ],
            class_groups: [
              px: [%{px: [Theme.from_theme("my-theme")]}]
            ]
          ]
        )

      assert custom_merge.("p-3 p-hello p-hallo") == "p-3 p-hello p-hallo"
      assert custom_merge.("px-3 px-hello px-hallo") == "px-hallo"
    end
  end

  describe "from_theme function" do
    test "creates a theme getter" do
      theme_getter = Theme.from_theme("spacing")
      assert Theme.theme_getter?(theme_getter)
      assert theme_getter.key == :spacing
    end

    test "theme getter extracts values from theme config" do
      theme_getter = Theme.from_theme("spacing")
      theme_config = %{spacing: ["1", "2", "4", "8"]}

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == ["1", "2", "4", "8"]
    end

    test "theme getter returns empty list for missing theme" do
      theme_getter = Theme.from_theme("missing")
      theme_config = %{spacing: ["1", "2", "4"]}

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == []
    end

    test "theme getter works with keyword list config" do
      theme_getter = Theme.from_theme("spacing")
      theme_config = [spacing: ["1", "2", "4", "8"]]

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == ["1", "2", "4", "8"]
    end

    test "theme getter works with atom keys" do
      theme_getter = Theme.from_theme(:spacing)
      theme_config = %{spacing: ["1", "2", "4", "8"]}

      result = Theme.call_theme_getter(theme_getter, theme_config)
      assert result == ["1", "2", "4", "8"]
    end
  end
end
