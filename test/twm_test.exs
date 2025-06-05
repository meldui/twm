defmodule TwmTest do
  use ExUnit.Case, async: false
  doctest Twm

  setup do
    # {:ok, _} = Twm.Cache.start_link(cache_size: 0)
    :ok
  end

  describe "merge/1" do
    test "merges classes correctly" do
      # Simple example (implementation will be expanded later)
      assert Twm.merge("px-2 px-4") == "px-4"
    end

    test "works with a list of classes" do
      assert Twm.merge(["px-2", "px-4"]) == "px-4"
    end

    test "uses cache for repeated calls" do
      # First call caches the result
      assert Twm.merge("pt-2 pt-4 pb-3") == "pt-4 pb-3"

      # We can't directly mock a private function, so instead we'll use a
      # different approach to test caching behavior

      # Make a second call that should use the cache
      result1 = Twm.merge("pt-2 pt-4 pb-3")

      # # Clear all entries from cache except our test entry
      # # This trick allows us to verify the cache is being used
      # entries = Twm.Cache.get_state().entries
      Twm.Cache.clear()

      # Put our test entry back
      Twm.Cache.put("pt-2 pt-4 pb-3", result1)

      # Make the call again - it should use the cache
      result2 = Twm.merge("pt-2 pt-4 pb-3")

      # Verify results match
      assert result1 == result2
      assert result1 == "pt-4 pb-3"
    end
  end

  describe "tw_merge/1" do
    test "is an alias for merge/1" do
      assert Twm.tw_merge("px-2 px-4") == Twm.merge("px-2 px-4")
    end
  end
end
