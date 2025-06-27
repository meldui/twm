#!/usr/bin/env elixir

# Quick benchmark script for Twm development
# Usage: mix run scripts/quick_benchmark.exs

defmodule QuickBenchmark do
  @moduledoc """
  Quick benchmarks for Twm development and testing.
  """

  def run do
    IO.puts("Running quick Twm benchmarks...")

    # Start the cache GenServer for benchmarking
    {:ok, _pid} = start_cache_if_needed()

    # Test data for quick benchmarks
    simple_classes = "px-2 py-1 px-3"

    medium_classes =
      "flex items-center justify-center bg-blue-500 bg-red-500 text-white text-black p-4 p-2"

    complex_classes =
      "font-medium text-sm leading-16 group/button relative isolate items-center justify-center overflow-hidden rounded-md outline-none transition focus-visible:ring focus-visible:ring-primary inline-flex bg-primary-50 ring ring-primary-200 text-primary dark:text-primary-900 hover:bg-primary-100 gap-4 px-6 py-4 p-0 size-24"

    # Array of classes for batch testing
    batch_classes = [
      "px-2 px-4",
      "py-1 py-3",
      "bg-red-500 bg-blue-500",
      "text-sm text-lg text-xl",
      "mt-2 mb-2 my-4",
      "hover:bg-red-500 hover:bg-blue-500",
      "focus:ring-2 focus:ring-4",
      "dark:text-white dark:text-gray-100",
      "lg:flex lg:hidden",
      "sm:p-2 md:p-4 lg:p-6"
    ]

    Benchee.run(
      %{
        "simple merge" => fn ->
          Twm.merge(simple_classes)
        end,
        "medium merge" => fn ->
          Twm.merge(medium_classes)
        end,
        "complex merge" => fn ->
          Twm.merge(complex_classes)
        end,
        "batch merge" => fn ->
          Enum.each(batch_classes, &Twm.merge/1)
        end,
        "list input" => fn ->
          Twm.merge(["px-2", "py-1", "px-3", "py-2"])
        end,
        "empty string" => fn ->
          Twm.merge("")
        end,
        "single class" => fn ->
          Twm.merge("flex")
        end,
        "no conflicts" => fn ->
          Twm.merge("flex items-center justify-center")
        end,
        "multiple conflicts" => fn ->
          Twm.merge("px-1 px-2 px-3 py-1 py-2 py-3 bg-red-500 bg-blue-500 bg-green-500")
        end,
        "arbitrary values" => fn ->
          Twm.merge("p-[20px] p-[30px] bg-[#ff0000] bg-[#00ff00]")
        end
      },
      time: 5,
      memory_time: 1,
      warmup: 1,
      formatters: [Benchee.Formatters.Console]
    )

    IO.puts("\nQuick benchmark complete!")
    IO.puts("For comprehensive benchmarks, run: mix run test/twm_benchmark.exs")

    # Clean up cache if we started it
    cleanup_cache()
  end

  defp start_cache_if_needed do
    case Process.whereis(Twm.Cache) do
      nil ->
        IO.puts("Starting Twm.Cache GenServer...")

        case Twm.Cache.start_link([]) do
          {:ok, pid} ->
            IO.puts("Twm.Cache started successfully (PID: #{inspect(pid)})")
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            IO.puts("Twm.Cache already started (PID: #{inspect(pid)})")
            {:ok, pid}

          error ->
            IO.puts("Failed to start Twm.Cache: #{inspect(error)}")
            error
        end

      pid ->
        IO.puts("Twm.Cache already running (PID: #{inspect(pid)})")
        {:ok, pid}
    end
  end

  defp cleanup_cache do
    case Process.whereis(Twm.Cache) do
      nil ->
        IO.puts("No cache to clean up")

      pid ->
        IO.puts("Stopping Twm.Cache GenServer...")
        Process.exit(pid, :normal)
        # Give it time to stop
        :timer.sleep(100)
        IO.puts("Cache cleanup complete")
    end
  end
end

# Run the quick benchmark
QuickBenchmark.run()
