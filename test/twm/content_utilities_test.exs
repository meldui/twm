defmodule Twm.ContentUtilitiesTest do
  @moduledoc """
  Tests for content utilities in Twm.
  """

  use ExUnit.Case, async: true

  describe "content utilities" do
    test "merges content utilities correctly" do
      result = Twm.merge("content-['hello'] content-[attr(data-content)]")
      assert result == "content-[attr(data-content)]"
    end
  end
end
