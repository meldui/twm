defmodule Twm.CacheTest do
  use ExUnit.Case, async: true
  doctest Twm.Cache

  setup do
    # Start a cache process specifically for each test
    cache_name = :"cache_#{:erlang.unique_integer([:positive])}"
    config = Twm.Config.extend(cache_size: 3)
    {:ok, pid} = Twm.Cache.start_link(name: cache_name, config: config)
    %{cache: cache_name, pid: pid}
  end

  describe "get/2" do
    test "returns :error for non-existent keys", %{cache: cache} do
      assert :error = Twm.Cache.get(cache, "non_existent_key")
    end

    test "returns {:ok, value} for existing keys", %{cache: cache} do
      Twm.Cache.put(cache, "key1", "value1")
      assert {:ok, "value1"} = Twm.Cache.get(cache, "key1")
    end
  end

  describe "put/3" do
    test "stores a value in the cache", %{cache: cache} do
      assert :ok = Twm.Cache.put(cache, "key1", "value1")
      assert {:ok, "value1"} = Twm.Cache.get(cache, "key1")
    end

    test "updates a value for an existing key", %{cache: cache} do
      Twm.Cache.put(cache, "key1", "value1")
      Twm.Cache.put(cache, "key1", "updated_value")
      assert {:ok, "updated_value"} = Twm.Cache.get(cache, "key1")
    end

    test "moves key to most recently used position when updated", %{cache: cache} do
      # Fill the cache with 3 items (max capacity)
      Twm.Cache.put(cache, "key1", "value1")
      Twm.Cache.put(cache, "key2", "value2")
      Twm.Cache.put(cache, "key3", "value3")

      # Update the least recently used key (key1)
      Twm.Cache.put(cache, "key1", "updated_value1")

      # Add a new key which should evict the now least recently used key (key2)
      Twm.Cache.put(cache, "key4", "value4")

      # key2 should be evicted
      assert :error = Twm.Cache.get(cache, "key2")

      # key1, key3, and key4 should still be present
      assert {:ok, "updated_value1"} = Twm.Cache.get(cache, "key1")
      assert {:ok, "value3"} = Twm.Cache.get(cache, "key3")
      assert {:ok, "value4"} = Twm.Cache.get(cache, "key4")
    end

    test "evicts least recently used item when cache is full", %{cache: cache} do
      # Fill the cache with 3 items (max capacity)
      Twm.Cache.put(cache, "key1", "value1")
      Twm.Cache.put(cache, "key2", "value2")
      Twm.Cache.put(cache, "key3", "value3")

      # Add a new item which should evict the least recently used (key1)
      Twm.Cache.put(cache, "key4", "value4")

      # key1 should be evicted
      assert :error = Twm.Cache.get(cache, "key1")

      # Other keys should still be present
      assert {:ok, "value2"} = Twm.Cache.get(cache, "key2")
      assert {:ok, "value3"} = Twm.Cache.get(cache, "key3")
      assert {:ok, "value4"} = Twm.Cache.get(cache, "key4")
    end
  end

  describe "clear/1" do
    test "removes all items from the cache", %{cache: cache} do
      # Add some items
      Twm.Cache.put(cache, "key1", "value1")
      Twm.Cache.put(cache, "key2", "value2")

      # Clear the cache
      assert :ok = Twm.Cache.clear(cache)

      # Verify items are removed
      assert :error = Twm.Cache.get(cache, "key1")
      assert :error = Twm.Cache.get(cache, "key2")
      assert 0 = Twm.Cache.size(cache)
    end
  end

  describe "size/1" do
    test "returns the number of items in the cache", %{cache: cache} do
      assert 0 = Twm.Cache.size(cache)

      Twm.Cache.put(cache, "key1", "value1")
      assert 1 = Twm.Cache.size(cache)

      Twm.Cache.put(cache, "key2", "value2")
      assert 2 = Twm.Cache.size(cache)

      # Updating an existing key doesn't change the size
      Twm.Cache.put(cache, "key1", "updated_value")
      assert 2 = Twm.Cache.size(cache)
    end
  end

  describe "resize/2" do
    test "increases cache capacity", %{cache: cache} do
      # Fill the cache
      Twm.Cache.put(cache, "key1", "value1")
      Twm.Cache.put(cache, "key2", "value2")
      Twm.Cache.put(cache, "key3", "value3")

      # Increase capacity
      assert :ok = Twm.Cache.resize(cache, 5)

      # Add more items that would have been evicted with the original capacity
      Twm.Cache.put(cache, "key4", "value4")
      Twm.Cache.put(cache, "key5", "value5")

      # All keys should be present
      assert {:ok, "value1"} = Twm.Cache.get(cache, "key1")
      assert {:ok, "value2"} = Twm.Cache.get(cache, "key2")
      assert {:ok, "value3"} = Twm.Cache.get(cache, "key3")
      assert {:ok, "value4"} = Twm.Cache.get(cache, "key4")
      assert {:ok, "value5"} = Twm.Cache.get(cache, "key5")
    end

    test "decreases cache capacity and evicts least recently used items", %{cache: cache} do
      # Fill the cache (key3 most recent, key1 least recent)
      Twm.Cache.put(cache, "key1", "value1")
      Twm.Cache.put(cache, "key2", "value2")
      Twm.Cache.put(cache, "key3", "value3")

      # Access keys to establish LRU order: key2 (most recent) -> key1 -> key3 (least recent)
      Twm.Cache.get(cache, "key1")
      Twm.Cache.get(cache, "key2")

      # Resize to 2 (should keep key2 and key1, drop key3)
      assert :ok = Twm.Cache.resize(cache, 2)

      # Verify key3 is gone and key1, key2 remain
      assert :error = Twm.Cache.get(cache, "key3")
      assert {:ok, "value1"} = Twm.Cache.get(cache, "key1")
      assert {:ok, "value2"} = Twm.Cache.get(cache, "key2")

      # Add another key (should keep key1, key2 since we just accessed them)
      Twm.Cache.put(cache, "key4", "value4")

      # LRU order is now: key4 (most recent) -> key2 -> key1 (least recent)
      # When we exceed capacity, key1 should be removed

      # Verify cache size is still 2
      assert 2 = Twm.Cache.size(cache)

      # key1 should be evicted, key2 and key4 should remain
      assert :error = Twm.Cache.get(cache, "key1")
      assert {:ok, "value2"} = Twm.Cache.get(cache, "key2")
      assert {:ok, "value4"} = Twm.Cache.get(cache, "key4")
    end
  end
end
