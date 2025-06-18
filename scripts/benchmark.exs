#!/usr/bin/env elixir

# Benchmark script for Twm
# Usage: mix run scripts/benchmark.exs

Mix.install([
  {:benchee, "~> 1.0"},
  {:jason, "~> 1.4"}
])

defmodule TwmBenchmark do
  @moduledoc """
  Benchmarks for Twm performance testing.
  """

  @benchmark_data_path "test/twm/tw-merge-benchmark-data.json"

  def run do
    IO.puts("Starting Twm benchmarks...")

    # Start the cache GenServer for benchmarking
    {:ok, _pid} = start_cache_if_needed()

    # Load benchmark data
    benchmark_data = load_benchmark_data()
    IO.puts("Loaded #{length(benchmark_data)} test cases")

    # Prepare test data - convert from mixed arrays to clean string arrays
    prepared_data = prepare_benchmark_data(benchmark_data)
    IO.puts("Prepared #{length(prepared_data)} test strings")

    Benchee.run(
      %{
        "init" => fn ->
          custom_merge = Twm.extend_tailwind_merge([])
          custom_merge.("")
        end,
        "simple" => fn ->
          Twm.merge("flex mx-10 px-10 mr-5 pr-5")
        end,
        "heavy" => fn ->
          Twm.merge(
            "font-medium text-sm leading-16 " <>
              "group/button relative isolate items-center justify-center overflow-hidden rounded-md outline-none transition [-webkit-app-region:no-drag] focus-visible:ring focus-visible:ring-primary " <>
              "inline-flex " <>
              "bg-primary-50 ring ring-primary-200 " <>
              "text-primary dark:text-primary-900 hover:bg-primary-100 " <>
              "font-medium text-sm leading-16 gap-4 px-6 py-4 " <>
              "p-0 size-24"
          )
        end,
        "collection with cache" => fn ->
          Enum.each(prepared_data, fn class_string ->
            Twm.merge(class_string)
          end)
        end,
        "collection without cache" => fn ->
          # Use direct merger to bypass cache
          config = Twm.Config.get_default()

          Enum.each(prepared_data, fn class_string ->
            Twm.Merger.merge_classes(class_string, config)
          end)
        end,
        "extend_tailwind_merge with cache" => fn ->
          custom_merge = Twm.extend_tailwind_merge([])

          Enum.each(prepared_data, fn class_string ->
            custom_merge.(class_string)
          end)
        end,
        "extend_tailwind_merge without cache" => fn ->
          custom_merge = Twm.extend_tailwind_merge(cache_size: 0)

          Enum.each(prepared_data, fn class_string ->
            custom_merge.(class_string)
          end)
        end
      },
      time: 10,
      memory_time: 2,
      formatters: [
        Benchee.Formatters.Console
      ]
    )

    IO.puts("Benchmark complete!")

    # Clean up cache if we started it
    cleanup_cache()
  end

  defp load_benchmark_data do
    case File.read(@benchmark_data_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            data

          {:error, reason} ->
            IO.puts("Failed to parse JSON: #{inspect(reason)}")
            []
        end

      {:error, reason} ->
        IO.puts("Failed to read benchmark data file: #{inspect(reason)}")
        IO.puts("Using fallback test data...")
        get_fallback_test_data()
    end
  end

  defp prepare_benchmark_data(data) do
    data
    |> Enum.map(&convert_test_item_to_string/1)
    |> Enum.filter(fn str -> str != "" end)
  end

  defp convert_test_item_to_string(item) when is_list(item) do
    item
    |> Enum.flat_map(&flatten_item/1)
    |> Enum.filter(&filter_valid_classes/1)
    |> Enum.join(" ")
  end

  defp flatten_item(item) when is_list(item) do
    Enum.flat_map(item, &flatten_item/1)
  end

  defp flatten_item(item) when is_binary(item), do: [item]
  defp flatten_item(nil), do: []
  defp flatten_item(false), do: []
  defp flatten_item(true), do: []
  defp flatten_item(_), do: []

  defp filter_valid_classes(class) when is_binary(class) and class != "", do: true
  defp filter_valid_classes(_), do: false

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

  defp get_fallback_test_data do
    [
      [
        "font-medium text-sm leading-16",
        "group/button relative isolate items-center justify-center overflow-hidden rounded-md outline-none transition [-webkit-app-region:no-drag] focus-visible:ring focus-visible:ring-primary",
        "inline-flex",
        "bg-primary-50 ring ring-primary-200",
        "text-primary dark:text-primary-900 hover:bg-primary-100",
        false,
        "font-medium text-sm leading-16 gap-4 px-6 py-4",
        nil,
        "p-0 size-24",
        nil
      ],
      [
        "relative isolate flex items-center rounded-md transition",
        "focus-within:ring focus-within:!ring-primary",
        "bg-base-bg-elevated dark:bg-base-bg ring ring-contrast-10",
        "hover:ring-contrast-20",
        nil,
        "mb-8 mx-6"
      ],
      ["flex-none absolute left-0 ml-6 pointer-events-none", "text-contrast-50"],
      [
        "font-medium text-sm leading-16",
        "w-full text-ellipsis bg-transparent px-8 py-6 outline-none placeholder:text-ellipsis placeholder:text-contrast-50",
        "pl-28",
        nil,
        nil
      ],
      [
        "whitespace-nowrap align-baseline",
        "text-[0.625rem] tracking-[0.01em] font-normal",
        ["leading-[1.1em]", nil],
        "mr-6 flex-none cursor-text"
      ],
      [
        "px-2 py-1 px-3",
        "bg-red-500 bg-blue-500",
        "text-sm text-lg",
        "mt-2 mb-2 my-3"
      ],
      [
        "hover:bg-red-500 hover:bg-blue-500",
        "focus:ring-2 focus:ring-4",
        "dark:text-white dark:text-gray-100"
      ]
    ]
  end
end

# Run the benchmark
TwmBenchmark.run()
