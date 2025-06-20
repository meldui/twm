defmodule Twm.Cache do
  @moduledoc """
  LRU (Least Recently Used) cache implementation for Twm.

  This module provides caching capabilities for Tailwind class merging
  operations to improve performance by avoiding redundant operations
  on the same class combinations.

  This module can be used in two ways:

  1. As a global cache for the main Twm functionality:

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

  2. As custom cache instances for custom merge functions:

  ```
  # Create a custom cache with a specific size
  cache_pid = Twm.Cache.ensure_started(20)

  # Use the cache directly
  Twm.Cache.put(cache_pid, "key", "value")
  ```

  """
  use GenServer
  require Logger

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
    config = Keyword.get(opts, :config, Twm.Config.get_default())

    GenServer.start_link(__MODULE__, %{config: config, config_cache_name: name}, name: name)
  end

  @doc """
  Ensures a cache server is started with the given size.

  If a server with the provided name already exists, it returns its pid.
  Otherwise, it starts a new server with the given cache size.

  ## Examples

      iex> cache_pid = Twm.Cache.ensure_started(100)
      iex> Twm.Cache.put(cache_pid, "key", "value")
      :ok
      iex> Twm.Cache.get(cache_pid, "key")
      {:ok, "value"}

  """
  @spec ensure_started(pos_integer(), atom() | nil) :: pid()
  def ensure_started(cache_size, name \\ __MODULE__)
      when is_integer(cache_size) and cache_size > 0 do
    if Process.whereis(name) do
      # If the named process exists, return its pid
      Process.whereis(name)
    else
      # Otherwise, start a new process
      {:ok, pid} = start_link(name: name, cache_size: cache_size)
      pid
    end
  end

  @doc """
  Retrieves a value from the cache by key.

  Returns `{:ok, value}` if the key exists, or `:error` if it doesn't.

  ## Examples

      # Start a cache server for doctest
      iex> cache_pid = Twm.Cache.ensure_started(10)
      iex> Twm.Cache.put(cache_pid, "key1", "value1")
      :ok
      iex> Twm.Cache.get(cache_pid, "key1")
      {:ok, "value1"}
      iex> Twm.Cache.get(cache_pid, "nonexistent_key")
      :error

  """
  @spec get(GenServer.server(), any()) :: {:ok, any()} | :error
  def get(server \\ __MODULE__, key) do
    case server do
      pid when is_pid(pid) ->
        # When a pid is provided, call it directly
        GenServer.call(pid, {:get, key})

      name when is_atom(name) ->
        # When a name is provided, check if the process exists
        if Process.whereis(name) do
          GenServer.call(name, {:get, key})
        else
          :error
        end
    end
  end

  @doc """
  Stores a key-value pair in the cache.

  If the key already exists, its value is updated and it becomes the most recently used.
  If the cache is full, the least recently used entry is removed.

  ## Examples

      # Start a cache server for doctest
      iex> cache_pid = Twm.Cache.ensure_started(10)
      iex> Twm.Cache.put(cache_pid, "key1", "value1")
      :ok
      iex> Twm.Cache.get(cache_pid, "key1")
      {:ok, "value1"}

  """
  @spec put(GenServer.server(), any(), any()) :: :ok
  def put(server \\ __MODULE__, key, value) do
    case server do
      pid when is_pid(pid) ->
        # When a pid is provided, call it directly
        GenServer.cast(pid, {:put, key, value})

      name when is_atom(name) ->
        # When a name is provided, check if the process exists
        if Process.whereis(name) do
          GenServer.cast(name, {:put, key, value})
        else
          :error
        end
    end
  end

  @doc """
  Clears all entries from the cache.

  ## Examples

      # Start a cache server for doctest
      iex> cache_pid = Twm.Cache.ensure_started(10)
      iex> Twm.Cache.put(cache_pid, "key1", "value1")
      :ok
      iex> Twm.Cache.clear(cache_pid)
      :ok
      iex> Twm.Cache.get(cache_pid, "key1")
      :error

  """
  @spec clear(GenServer.server()) :: :ok
  def clear(server \\ __MODULE__) do
    case server do
      pid when is_pid(pid) ->
        # When a pid is provided, call it directly
        GenServer.cast(pid, :clear)
        :ok

      name when is_atom(name) ->
        # When a name is provided, check if the process exists
        if Process.whereis(name) do
          GenServer.cast(name, :clear)
          :ok
        else
          :error
        end
    end
  end

  @doc """
  Returns the current size of the cache.

  ## Examples

      # Start a cache server for doctest
      iex> cache_pid = Twm.Cache.ensure_started(10)
      iex> Twm.Cache.put(cache_pid, "key1", "value1")
      :ok
      iex> Twm.Cache.put(cache_pid, "key2", "value2")
      :ok
      iex> Twm.Cache.size(cache_pid)
      2

  """
  @spec size(GenServer.server()) :: non_neg_integer()
  def size(server \\ __MODULE__) do
    case server do
      pid when is_pid(pid) ->
        # When a pid is provided, call it directly
        GenServer.call(pid, :size)

      name when is_atom(name) ->
        # When a name is provided, check if the process exists
        if Process.whereis(name) do
          GenServer.call(name, :size)
        else
          0
        end
    end
  end

  @doc """
  Changes the maximum capacity of the cache.

  If the new size is smaller than the current number of entries,
  the least recently used entries are removed until the cache fits
  the new size.

  ## Examples

      # Start a cache server for doctest
      iex> cache_pid = Twm.Cache.ensure_started(100)
      iex> # Fill cache with a few entries
      iex> Twm.Cache.put(cache_pid, "key1", "value1")
      :ok
      iex> Twm.Cache.put(cache_pid, "key2", "value2")
      :ok
      iex> Twm.Cache.resize(cache_pid, 1)
      :ok
      iex> Twm.Cache.size(cache_pid)
      1

  """
  @spec resize(GenServer.server(), pos_integer()) :: :ok
  def resize(server \\ __MODULE__, new_size) when is_integer(new_size) and new_size > 0 do
    case server do
      pid when is_pid(pid) ->
        # When a pid is provided, call it directly
        GenServer.cast(pid, {:resize, new_size})
        :ok

      name when is_atom(name) ->
        # When a name is provided, check if the process exists
        if Process.whereis(name) do
          GenServer.cast(name, {:resize, new_size})
        end

        :ok
    end
  end

  # Debug helper function - only used in development/testing
  @doc false
  def get_state(server \\ __MODULE__) do
    case server do
      pid when is_pid(pid) ->
        # When a pid is provided, call it directly
        GenServer.call(pid, :get_state)

      name when is_atom(name) ->
        # When a name is provided, check if the process exists
        if Process.whereis(name) do
          GenServer.call(name, :get_state)
        else
          :error
        end
    end
  end

  def get_config(name \\ __MODULE__) do
    # {:error, "Config not found in cache"}
    safe_ets_lookup(fn ->
      case :ets.lookup(name, :config) do
        [{:config, config}] ->
          {:ok, config}

        [] ->
          {:error, "Config not found in cache"}
      end
    end)
  end

  def get_class_group_utils(name \\ __MODULE__) do
    # {:error, "Class group utils not found in cache"}
    safe_ets_lookup(fn ->
      case :ets.lookup(name, :class_group_utils) do
        [{:class_group_utils, class_group_utils}] ->
          {:ok, class_group_utils}

        [] ->
          {:error, "Class group utils not found in cache"}
      end
    end)
  end

  defp safe_ets_lookup(func) do
    try do
      func.()
    rescue
      ArgumentError -> {:error, "Cache not initialized"}
    end
  end

  # Server Callbacks

  @impl true
  def init(%{config: config, config_cache_name: name}) do
    # State structure:
    # %{
    #   entries: %{key => value},        # Map of cached key-value pairs
    #   access_order: [key1, key2, ...], # List with most recently used keys first
    #   max_size: cache_size             # Maximum number of entries
    # }
    :ets.new(name, [:named_table, :protected, :set, read_concurrency: true])

    :ets.insert(name, {:config, config})

    :ets.insert(
      name,
      {:class_group_utils, Twm.ClassGroupUtils.create_class_group_utils(config)}
    )

    {:ok, %{entries: %{}, access_order: [], max_size: config[:cache_size]}}
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
