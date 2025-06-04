defmodule Twm.ValidatorsTest do
  use ExUnit.Case, async: true

  alias Twm.Validators

  describe "is_any/0" do
    test "always returns true" do
      assert Validators.any?() == true
      assert Validators.any?("test") == true
      assert Validators.any?(123) == true
      assert Validators.any?([1, 2, 3]) == true
      assert Validators.any?(%{key: "value"}) == true
    end
  end

  describe "is_any_non_arbitrary/1" do
    test "returns true for non-arbitrary values" do
      assert Validators.is_any_non_arbitrary("test") == true
      assert Validators.is_any_non_arbitrary("1234-hello-world") == true
      assert Validators.is_any_non_arbitrary("[hello") == true
      assert Validators.is_any_non_arbitrary("hello]") == true
      assert Validators.is_any_non_arbitrary("[)") == true
      assert Validators.is_any_non_arbitrary("(hello]") == true
    end

    test "returns false for arbitrary values" do
      assert Validators.is_any_non_arbitrary("[test]") == false
      assert Validators.is_any_non_arbitrary("[label:test]") == false
      assert Validators.is_any_non_arbitrary("(test)") == false
      assert Validators.is_any_non_arbitrary("(label:test)") == false
    end
  end

  describe "is_arbitrary_image/1" do
    test "returns true for arbitrary image values" do
      assert Validators.is_arbitrary_image("[url:var(--my-url)]") == true
      assert Validators.is_arbitrary_image("[url(something)]") == true
      assert Validators.is_arbitrary_image("[url:bla]") == true
      assert Validators.is_arbitrary_image("[image:bla]") == true
      assert Validators.is_arbitrary_image("[linear-gradient(something)]") == true
      assert Validators.is_arbitrary_image("[repeating-conic-gradient(something)]") == true
    end

    test "returns false for non-image values" do
      assert Validators.is_arbitrary_image("[var(--my-url)]") == false
      assert Validators.is_arbitrary_image("[bla]") == false
      assert Validators.is_arbitrary_image("url:2px") == false
      assert Validators.is_arbitrary_image("url(2px)") == false
    end
  end

  describe "is_arbitrary_length/1" do
    test "returns true for arbitrary length values" do
      assert Validators.is_arbitrary_length("[3.7%]") == true
      assert Validators.is_arbitrary_length("[481px]") == true
      assert Validators.is_arbitrary_length("[19.1rem]") == true
      assert Validators.is_arbitrary_length("[50vw]") == true
      assert Validators.is_arbitrary_length("[56vh]") == true
      assert Validators.is_arbitrary_length("[length:var(--arbitrary)]") == true
    end

    test "returns false for non-length values" do
      assert Validators.is_arbitrary_length("1") == false
      assert Validators.is_arbitrary_length("3px") == false
      assert Validators.is_arbitrary_length("1d5") == false
      assert Validators.is_arbitrary_length("[1]") == false
      assert Validators.is_arbitrary_length("[12px") == false
      assert Validators.is_arbitrary_length("12px]") == false
      assert Validators.is_arbitrary_length("one") == false
    end
  end

  describe "is_arbitrary_number/1" do
    test "returns true for arbitrary number values" do
      assert Validators.is_arbitrary_number("[number:black]") == true
      assert Validators.is_arbitrary_number("[number:bla]") == true
      assert Validators.is_arbitrary_number("[number:230]") == true
      assert Validators.is_arbitrary_number("[450]") == true
    end

    test "returns false for non-number values" do
      assert Validators.is_arbitrary_number("[2px]") == false
      assert Validators.is_arbitrary_number("[bla]") == false
      assert Validators.is_arbitrary_number("[black]") == false
      assert Validators.is_arbitrary_number("black") == false
      assert Validators.is_arbitrary_number("450") == false
    end
  end

  describe "is_arbitrary_position/1" do
    test "returns true for arbitrary position values" do
      assert Validators.is_arbitrary_position("[position:2px]") == true
      assert Validators.is_arbitrary_position("[position:bla]") == true
      assert Validators.is_arbitrary_position("[percentage:bla]") == true
    end

    test "returns false for non-position values" do
      assert Validators.is_arbitrary_position("[2px]") == false
      assert Validators.is_arbitrary_position("[bla]") == false
      assert Validators.is_arbitrary_position("position:2px") == false
    end
  end

  describe "is_arbitrary_shadow/1" do
    test "returns true for arbitrary shadow values" do
      assert Validators.is_arbitrary_shadow("[0_35px_60px_-15px_rgba(0,0,0,0.3)]") == true
      assert Validators.is_arbitrary_shadow("[inset_0_1px_0,inset_0_-1px_0]") == true
      assert Validators.is_arbitrary_shadow("[0_0_#00f]") == true
      assert Validators.is_arbitrary_shadow("[.5rem_0_rgba(5,5,5,5)]") == true
      assert Validators.is_arbitrary_shadow("[-.5rem_0_#123456]") == true
      assert Validators.is_arbitrary_shadow("[0.5rem_-0_#123456]") == true
      assert Validators.is_arbitrary_shadow("[0.5rem_-0.005vh_#123456]") == true
      assert Validators.is_arbitrary_shadow("[0.5rem_-0.005vh]") == true
    end

    test "returns false for non-shadow values" do
      assert Validators.is_arbitrary_shadow("[rgba(5,5,5,5)]") == false
      assert Validators.is_arbitrary_shadow("[#00f]") == false
      assert Validators.is_arbitrary_shadow("[something-else]") == false
    end
  end

  describe "is_arbitrary_size/1" do
    test "returns true for arbitrary size values" do
      assert Validators.is_arbitrary_size("[size:2px]") == true
      assert Validators.is_arbitrary_size("[size:bla]") == true
      assert Validators.is_arbitrary_size("[length:bla]") == true
    end

    test "returns false for non-size values" do
      assert Validators.is_arbitrary_size("[2px]") == false
      assert Validators.is_arbitrary_size("[bla]") == false
      assert Validators.is_arbitrary_size("size:2px") == false
      assert Validators.is_arbitrary_size("[percentage:bla]") == false
    end
  end

  describe "is_arbitrary_value/1" do
    test "returns true for arbitrary values" do
      assert Validators.is_arbitrary_value("[1]") == true
      assert Validators.is_arbitrary_value("[bla]") == true
      assert Validators.is_arbitrary_value("[not-an-arbitrary-value?]") == true
      assert Validators.is_arbitrary_value("[auto,auto,minmax(0,1fr),calc(100vw-50%)]") == true
    end

    test "returns false for non-arbitrary values" do
      assert Validators.is_arbitrary_value("[]") == false
      assert Validators.is_arbitrary_value("[1") == false
      assert Validators.is_arbitrary_value("1]") == false
      assert Validators.is_arbitrary_value("1") == false
      assert Validators.is_arbitrary_value("one") == false
      assert Validators.is_arbitrary_value("o[n]e") == false
    end
  end

  describe "is_arbitrary_variable/1" do
    test "returns true for arbitrary variable values" do
      assert Validators.is_arbitrary_variable("(1)") == true
      assert Validators.is_arbitrary_variable("(bla)") == true
      assert Validators.is_arbitrary_variable("(not-an-arbitrary-value?)") == true
      assert Validators.is_arbitrary_variable("(--my-arbitrary-variable)") == true
      assert Validators.is_arbitrary_variable("(label:--my-arbitrary-variable)") == true
    end

    test "returns false for non-arbitrary variable values" do
      assert Validators.is_arbitrary_variable("()") == false
      assert Validators.is_arbitrary_variable("(1") == false
      assert Validators.is_arbitrary_variable("1)") == false
      assert Validators.is_arbitrary_variable("1") == false
      assert Validators.is_arbitrary_variable("one") == false
      assert Validators.is_arbitrary_variable("o(n)e") == false
    end
  end

  describe "is_arbitrary_variable_family_name/1" do
    test "returns true for arbitrary variable family name values" do
      assert Validators.is_arbitrary_variable_family_name("(family-name:test)") == true
    end

    test "returns false for non-family name values" do
      assert Validators.is_arbitrary_variable_family_name("(other:test)") == false
      assert Validators.is_arbitrary_variable_family_name("(test)") == false
      assert Validators.is_arbitrary_variable_family_name("family-name:test") == false
    end
  end

  describe "is_arbitrary_variable_image/1" do
    test "returns true for arbitrary variable image values" do
      assert Validators.is_arbitrary_variable_image("(image:test)") == true
      assert Validators.is_arbitrary_variable_image("(url:test)") == true
    end

    test "returns false for non-image values" do
      assert Validators.is_arbitrary_variable_image("(other:test)") == false
      assert Validators.is_arbitrary_variable_image("(test)") == false
      assert Validators.is_arbitrary_variable_image("image:test") == false
    end
  end

  describe "is_arbitrary_variable_length/1" do
    test "returns true for arbitrary variable length values" do
      assert Validators.is_arbitrary_variable_length("(length:test)") == true
    end

    test "returns false for non-length values" do
      assert Validators.is_arbitrary_variable_length("(other:test)") == false
      assert Validators.is_arbitrary_variable_length("(test)") == false
      assert Validators.is_arbitrary_variable_length("length:test") == false
    end
  end

  describe "is_arbitrary_variable_position/1" do
    test "returns true for arbitrary variable position values" do
      assert Validators.is_arbitrary_variable_position("(position:test)") == true
    end

    test "returns false for non-position values" do
      assert Validators.is_arbitrary_variable_position("(other:test)") == false
      assert Validators.is_arbitrary_variable_position("(test)") == false
      assert Validators.is_arbitrary_variable_position("position:test") == false
      assert Validators.is_arbitrary_variable_position("percentage:test") == false
    end
  end

  describe "is_arbitrary_variable_shadow/1" do
    test "returns true for arbitrary variable shadow values" do
      assert Validators.is_arbitrary_variable_shadow("(shadow:test)") == true
      assert Validators.is_arbitrary_variable_shadow("(test)") == true
    end

    test "returns false for non-shadow values" do
      assert Validators.is_arbitrary_variable_shadow("(other:test)") == false
      assert Validators.is_arbitrary_variable_shadow("shadow:test") == false
    end
  end

  describe "is_arbitrary_variable_size/1" do
    test "returns true for arbitrary variable size values" do
      assert Validators.is_arbitrary_variable_size("(size:test)") == true
      assert Validators.is_arbitrary_variable_size("(length:test)") == true
    end

    test "returns false for non-size values" do
      assert Validators.is_arbitrary_variable_size("(other:test)") == false
      assert Validators.is_arbitrary_variable_size("(test)") == false
      assert Validators.is_arbitrary_variable_size("size:test") == false
      assert Validators.is_arbitrary_variable_size("(percentage:test)") == false
    end
  end

  describe "is_fraction/1" do
    test "returns true for fraction values" do
      assert Validators.is_fraction("1/2") == true
      assert Validators.is_fraction("123/209") == true
    end

    test "returns false for non-fraction values" do
      assert Validators.is_fraction("1") == false
      assert Validators.is_fraction("1/2/3") == false
      assert Validators.is_fraction("[1/2]") == false
    end
  end

  describe "is_integer/1" do
    test "returns true for integer values" do
      assert Validators.is_integer_value("1") == true
      assert Validators.is_integer_value("123") == true
      assert Validators.is_integer_value("8312") == true
    end

    test "returns false for non-integer values" do
      assert Validators.is_integer_value("[8312]") == false
      assert Validators.is_integer_value("[2]") == false
      assert Validators.is_integer_value("[8312px]") == false
      assert Validators.is_integer_value("[8312%]") == false
      assert Validators.is_integer_value("[8312rem]") == false
      assert Validators.is_integer_value("8312.2") == false
      assert Validators.is_integer_value("1.2") == false
      assert Validators.is_integer_value("one") == false
      assert Validators.is_integer_value("1/2") == false
      assert Validators.is_integer_value("1%") == false
      assert Validators.is_integer_value("1px") == false
    end
  end

  describe "is_number/1" do
    test "returns true for number values" do
      assert Validators.is_number_value("1") == true
      assert Validators.is_number_value("123") == true
      assert Validators.is_number_value("8312") == true
      assert Validators.is_number_value("8312.2") == true
      assert Validators.is_number_value("1.2") == true
    end

    test "returns false for non-number values" do
      assert Validators.is_number_value("[8312]") == false
      assert Validators.is_number_value("[2]") == false
      assert Validators.is_number_value("[8312px]") == false
      assert Validators.is_number_value("[8312%]") == false
      assert Validators.is_number_value("[8312rem]") == false
      assert Validators.is_number_value("one") == false
      assert Validators.is_number_value("1/2") == false
      assert Validators.is_number_value("1%") == false
      assert Validators.is_number_value("1px") == false
    end
  end

  describe "percent?/1" do
    test "returns true for percentage values" do
      assert Validators.percent?("1%") == true
      assert Validators.percent?("100.001%") == true
      assert Validators.percent?(".01%") == true
      assert Validators.percent?("0%") == true
    end

    test "returns false for non-percentage values" do
      assert Validators.percent?("0") == false
      assert Validators.percent?("one%") == false
    end
  end

  describe "is_tshirt_size/1" do
    test "returns true for t-shirt size values" do
      assert Validators.is_tshirt_size("xs") == true
      assert Validators.is_tshirt_size("sm") == true
      assert Validators.is_tshirt_size("md") == true
      assert Validators.is_tshirt_size("lg") == true
      assert Validators.is_tshirt_size("xl") == true
      assert Validators.is_tshirt_size("2xl") == true
      assert Validators.is_tshirt_size("2.5xl") == true
      assert Validators.is_tshirt_size("10xl") == true
      assert Validators.is_tshirt_size("2xs") == true
      assert Validators.is_tshirt_size("2lg") == true
    end

    test "returns false for non-t-shirt size values" do
      assert Validators.is_tshirt_size("") == false
      assert Validators.is_tshirt_size("hello") == false
      assert Validators.is_tshirt_size("1") == false
      assert Validators.is_tshirt_size("xl3") == false
      assert Validators.is_tshirt_size("2xl3") == false
      assert Validators.is_tshirt_size("-xl") == false
      assert Validators.is_tshirt_size("[sm]") == false
    end
  end
end
