defmodule Twm.Parser.ClassNameTest do
  use ExUnit.Case, async: true
  alias Twm.Parser.ClassName

  describe "do_parse_class_name/1" do
    test "parses a simple class name" do
      result = ClassName.do_parse_class_name("text-red-500")

      assert result == %{
               is_external: false,
               modifiers: [],
               has_important_modifier: false,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end

    test "parses a class name with modifiers" do
      result = ClassName.do_parse_class_name("hover:focus:text-red-500")

      assert result == %{
               is_external: false,
               modifiers: ["hover", "focus"],
               has_important_modifier: false,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end

    test "parses a class name with important modifier at the end" do
      result = ClassName.do_parse_class_name("text-red-500!")

      assert result == %{
               is_external: false,
               modifiers: [],
               has_important_modifier: true,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end

    test "parses a class name with important modifier at the beginning" do
      result = ClassName.do_parse_class_name("!text-red-500")

      assert result == %{
               is_external: false,
               modifiers: [],
               has_important_modifier: true,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end

    test "parses a class name with a postfix modifier" do
      result = ClassName.do_parse_class_name("bg-red-500/50")

      assert result == %{
               is_external: false,
               modifiers: [],
               has_important_modifier: false,
               base_class_name: "bg-red-500",
               maybe_postfix_modifier_position: 10
             }
    end

    test "parses a class name with modifiers and brackets" do
      result = ClassName.do_parse_class_name("hover:bg-[#123456]")

      assert result == %{
               is_external: false,
               modifiers: ["hover"],
               has_important_modifier: false,
               base_class_name: "bg-[#123456]",
               maybe_postfix_modifier_position: nil
             }
    end

    test "correctly handles nested brackets" do
      result = ClassName.do_parse_class_name("hover:bg-[rgb(123,45,67)]")

      assert result == %{
               is_external: false,
               modifiers: ["hover"],
               has_important_modifier: false,
               base_class_name: "bg-[rgb(123,45,67)]",
               maybe_postfix_modifier_position: nil
             }
    end

    test "handles colons inside brackets" do
      result = ClassName.do_parse_class_name("bg-[url('https://example.com')]")

      assert result == %{
               is_external: false,
               modifiers: [],
               has_important_modifier: false,
               base_class_name: "bg-[url('https://example.com')]",
               maybe_postfix_modifier_position: nil
             }
    end
  end

  describe "create_parse_class_name/1" do
    test "creates a function that parses class names" do
      parse_fn = ClassName.create_parse_class_name(%{})
      result = parse_fn.("hover:text-red-500")

      assert result == %{
               is_external: false,
               modifiers: ["hover"],
               has_important_modifier: false,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end

    test "handles prefix when configured" do
      parse_fn = ClassName.create_parse_class_name(%{prefix: "tw"})

      # When prefix matches
      result = parse_fn.("tw:hover:text-red-500")

      assert result == %{
               is_external: false,
               modifiers: ["hover"],
               has_important_modifier: false,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }

      # When prefix doesn't match
      result = parse_fn.("twm:text-red-500")

      assert result == %{
               is_external: true,
               modifiers: [],
               has_important_modifier: false,
               base_class_name: "twm:text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end

    test "uses experimental parser when configured" do
      experimental_fn = fn %{class_name: class_name} ->
        %{
          modifiers: ["experimental"],
          has_important_modifier: false,
          base_class_name: class_name,
          maybe_postfix_modifier_position: nil
        }
      end

      parse_fn =
        ClassName.create_parse_class_name(%{experimental_parse_class_name: experimental_fn})

      result = parse_fn.("text-red-500")

      assert result == %{
               modifiers: ["experimental"],
               has_important_modifier: false,
               base_class_name: "text-red-500",
               maybe_postfix_modifier_position: nil
             }
    end
  end

  describe "strip_important_modifier/1" do
    test "removes important modifier from the end" do
      assert ClassName.strip_important_modifier("text-red-500!") == "text-red-500"
    end

    test "removes important modifier from the beginning" do
      assert ClassName.strip_important_modifier("!text-red-500") == "text-red-500"
    end

    test "returns the same string when no important modifier is present" do
      assert ClassName.strip_important_modifier("text-red-500") == "text-red-500"
    end
  end
end
