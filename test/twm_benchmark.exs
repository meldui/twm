defmodule TwmBenchmark do
  @moduledoc """
  Benchmarks for Twm performance testing.

  Run with: mix run test/twm_benchmark.exs
  """

  @benchmark_data_path "test/twm/tw-merge-benchmark-data.json"

  def run do
    IO.puts("Starting Twm benchmarks...")

    # Load benchmark data
    benchmark_data = load_benchmark_data()
    IO.puts("Loaded #{length(benchmark_data)} test cases")

    # Prepare test data - convert from mixed arrays to clean string arrays
    prepared_data = prepare_benchmark_data(benchmark_data)
    IO.puts("Prepared #{length(prepared_data)} test strings")

    # CACHE BEHAVIOR ANALYSIS:
    # - Twm.merge/1 uses global Twm.Cache GenServer (fast when cache running)
    # - Twm.Merger.merge_classes/2 bypasses cache completely (always slow)
    # - extend_tailwind_merge/1 creates custom functions that use merge_with_config/2
    #   which directly calls Twm.Merger.merge_classes/2, bypassing global cache
    # - cache_size parameter in extend_tailwind_merge is not yet implemented

    Benchee.run(
      %{
        "init" => fn ->
          custom_merge = Twm.extend_tailwind_merge([])
          custom_merge.("")
        end,
        "simple" => fn ->
          run_with_cache(fn -> Twm.merge("flex mx-10 px-10 mr-5 pr-5") end)
        end,
        "heavy" => fn ->
          run_with_cache(fn ->
            Twm.merge(
              "font-medium text-sm leading-16 " <>
                "group/button relative isolate items-center justify-center overflow-hidden rounded-md outline-none transition [-webkit-app-region:no-drag] focus-visible:ring focus-visible:ring-primary " <>
                "inline-flex " <>
                "bg-primary-50 ring ring-primary-200 " <>
                "text-primary dark:text-primary-900 hover:bg-primary-100 " <>
                "font-medium text-sm leading-16 gap-4 px-6 py-4 " <>
                "p-0 size-24"
            )
          end)
        end,
        "collection with cache" => fn ->
          run_with_cache(fn ->
            Enum.each(prepared_data, fn class_string ->
              Twm.merge(class_string)
            end)
          end)
        end,
        "collection without cache" => fn ->
          run_without_cache(fn ->
            config = Twm.Config.get_default()

            Enum.each(prepared_data, fn class_string ->
              Twm.Merger.merge_classes(class_string, config)
            end)
          end)
        end,
        "extend_tailwind_merge (no global cache)" => fn ->
          # extend_tailwind_merge creates functions that bypass global cache
          # and directly use Twm.Merger.merge_classes - same performance as no-cache
          custom_merge = Twm.extend_tailwind_merge([])

          Enum.each(prepared_data, fn class_string ->
            custom_merge.(class_string)
          end)
        end,
        "extend_tailwind_merge (cache_size param)" => fn ->
          # extend_tailwind_merge with cache_size parameter
          # Currently not implemented to create internal cache, same as above
          custom_merge = Twm.extend_tailwind_merge(cache_size: 1000)

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

    # Ensure cache is properly cleaned up
    stop_cache_if_running()
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

  defp run_with_cache(fun) do
    start_cache_if_needed()
    fun.()
  end

  defp run_without_cache(fun) do
    stop_cache_if_running()
    fun.()
  end

  defp start_cache_if_needed do
    case Process.whereis(Twm.Cache) do
      nil ->
        case Twm.Cache.start_link(cache_size: 1000) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          _error -> :ok
        end

      _pid ->
        :ok
    end
  end

  defp stop_cache_if_running do
    case Process.whereis(Twm.Cache) do
      nil ->
        :ok

      pid ->
        Process.exit(pid, :normal)
        :timer.sleep(50)
        :ok
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
      ]
    ]
  end
end

# Run the benchmark when this file is executed
TwmBenchmark.run()
