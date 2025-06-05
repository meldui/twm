defmodule Twm.Cache do
  @moduledoc """
  LRU (Least Recently Used) cache implementation for Twm.

  This module provides caching capabilities for Tailwind class merging
  operations to improve performance by avoiding redundant operations
  on the same class combinations.

  To use this module, include it into the target application at below:

  ```
  defmodule Twm.Application do
    @moduledoc false

    use Application

    @impl true
    def start(_type, _args) do
      children = [
        # Start the Twm.Cache with default configuration
        {Twm.Cache, []}
      ]

      opts = [strategy: :one_for_one, name: Twm.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  ```

  """
  use GenServer
  require Logger

  @default_cache_size 500

  # Client API

  @doc """
  Starts the cache server.

  ## Options

  * `:name` - The name to register the cache process with. Defaults to `Twm.Cache`.
  * `:cache_size` - The maximum number of entries in the cache. Defaults to 500.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    cache_size = Keyword.get(opts, :cache_size, @default_cache_size)

    GenServer.start_link(__MODULE__, cache_size, name: name)
  end

  @doc """
  Retrieves a value from the cache by key.

  Returns `{:ok, value}` if the key exists, or `:error` if it doesn't.
  """
  @spec get(GenServer.server(), any()) :: {:ok, any()} | :error
  def get(server \\ __MODULE__, key) do
    if Process.whereis(server) do
      GenServer.call(server, {:get, key})
    else
      :error
    end
  end

  @doc """
  Stores a key-value pair in the cache.

  If the key already exists, its value is updated and it becomes the most recently used.
  If the cache is full, the least recently used entry is removed.
  """
  @spec put(GenServer.server(), any(), any()) :: :ok
  def put(server \\ __MODULE__, key, value) do
    if Process.whereis(server) do
      GenServer.cast(server, {:put, key, value})
    else
      :error
    end
  end

  @doc """
  Clears all entries from the cache.
  """
  @spec clear(GenServer.server()) :: :ok
  def clear(server \\ __MODULE__) do
    if Process.whereis(server) do
      GenServer.cast(server, :clear)
    else
      :error
    end
  end

  @doc """
  Returns the current size of the cache.
  """
  @spec size(GenServer.server()) :: non_neg_integer()
  def size(server \\ __MODULE__) do
    if Process.whereis(server) do
      GenServer.call(server, :size)
    else
      0
    end
  end

  @doc """
  Changes the maximum capacity of the cache.

  If the new size is smaller than the current number of entries,
  the least recently used entries are removed until the cache fits
  the new size.
  """
  @spec resize(GenServer.server(), pos_integer()) :: :ok
  def resize(server \\ __MODULE__, new_size) when is_integer(new_size) and new_size > 0 do
    if Process.whereis(server) do
      GenServer.cast(server, {:resize, new_size})
    end

    :ok
  end

  # Debug helper function - only used in development/testing
  @doc false
  def get_state(server \\ __MODULE__) do
    if Process.whereis(server) do
      GenServer.call(server, :get_state)
    else
      :error
    end
  end

  # Server Callbacks

  @impl true
  def init(cache_size) do
    # State structure:
    # %{
    #   entries: %{key => value},        # Map of cached key-value pairs
    #   access_order: [key1, key2, ...], # List with most recently used keys first
    #   max_size: cache_size             # Maximum number of entries
    # }
    {:ok, %{entries: %{}, access_order: [], max_size: cache_size}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case Map.fetch(state.entries, key) do
      {:ok, value} ->
        # Move key to front of access_order (most recently used)
        # Remove the key from its current position and add it to the front
        new_access_order = [key | List.delete(state.access_order, key)]
        new_state = %{state | access_order: new_access_order}
        {:reply, {:ok, value}, new_state}

      :error ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:size, _from, state) do
    {:reply, map_size(state.entries), state}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    # Check if key already exists
    {new_entries, new_access_order} =
      case Map.has_key?(state.entries, key) do
        true ->
          # Update existing key and move to front of access order
          updated_access_order = [key | List.delete(state.access_order, key)]

          {
            Map.put(state.entries, key, value),
            updated_access_order
          }

        false ->
          # Add new key-value pair
          updated_access_order = [key | state.access_order]

          {
            Map.put(state.entries, key, value),
            updated_access_order
          }
      end

    # Ensure we don't exceed max_size
    {final_entries, final_access_order} =
      if map_size(new_entries) > state.max_size do
        # Get the least recently used key (last in the list)
        lru_key = List.last(new_access_order)

        {
          Map.delete(new_entries, lru_key),
          Enum.drop(new_access_order, -1)
        }
      else
        {new_entries, new_access_order}
      end

    {:noreply, %{state | entries: final_entries, access_order: final_access_order}}
  end

  @impl true
  def handle_cast(:clear, state) do
    {:noreply, %{state | entries: %{}, access_order: []}}
  end

  @impl true
  def handle_cast({:resize, new_size}, state) do
    # If new size is smaller, we need to remove oldest entries
    {final_entries, final_access_order} =
      if map_size(state.entries) > new_size do
        # Keep only the most recently used keys
        # Since access_order has most recent keys at the front,
        # we take the first new_size elements
        keys_to_keep = Enum.take(state.access_order, new_size)

        # Create a new entries map with only the keys we want to keep
        kept_entries = Map.take(state.entries, keys_to_keep)

        {kept_entries, keys_to_keep}
      else
        {state.entries, state.access_order}
      end

    {:noreply,
     %{state | entries: final_entries, access_order: final_access_order, max_size: new_size}}
  end
end
