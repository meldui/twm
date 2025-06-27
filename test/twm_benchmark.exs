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
        # "init" => fn _ ->
        #   Enum.each(1..1322, fn _ ->
        #     Twm.merge("")
        #   end)
        # end,
        # "simple" => fn _ ->
        #   run_with_cache(fn ->
        #     Enum.each(1..1322, fn _ -> Twm.merge("flex mx-10 px-10 mr-5 pr-5") end)
        #   end)
        # end,
        # "heavy" => fn _ ->
        #   run_with_cache(fn ->
        #     Enum.each(1..1322, fn _ ->
        #       Twm.merge(
        #         "font-medium text-sm leading-16 " <>
        #           "group/button relative isolate items-center justify-center overflow-hidden rounded-md outline-none transition [-webkit-app-region:no-drag] focus-visible:ring focus-visible:ring-primary " <>
        #           "inline-flex " <>
        #           "bg-primary-50 ring ring-primary-200 " <>
        #           "text-primary dark:text-primary-900 hover:bg-primary-100 " <>
        #           "font-medium text-sm leading-16 gap-4 px-6 py-4 " <>
        #           "p-0 size-24"
        #       )
        #     end)
        #   end)
        # end
        "collection with cache" =>
          {fn {config, input_classes} ->
             # config = Twm.Config.get_default()
             # Twm.merge(input, config)
             # IO.inspect(input, label: "Input")

             # IO.inspect("coming here")

             run_with_cache(fn ->
               # Enum.each(input, fn class_string ->
               Twm.merge(input_classes)
               # end)
             end)
           end,
           before_scenario: fn input ->
             config = Twm.Config.get_default()
             {config, input.()}
           end},
        "collection without cache" => {
          fn {config, input_classes} ->
            # config = Twm.Config.get_default()
            Twm.merge(input_classes, config)
          end,
          before_scenario: fn input ->
            config = Twm.Config.get_default()
            stop_cache_if_running()
            {config, input.()}
          end
        }
      },
      inputs: %{"benchmark_data" => prepare_input()},
      time: 10,
      memory_time: 2,
      formatters: [
        Benchee.Formatters.Console
      ],
      before_scenario: fn input ->
        start_cache_if_needed()
        input
      end,
      after_scenario: fn _ ->
        stop_cache_if_running()
      end
    )

    IO.puts("Benchmark complete!")

    # Ensure cache is properly cleaned up
    stop_cache_if_running()
  end

  defp prepare_input() do
    benchmark_data =
      load_benchmark_data() ++
        load_benchmark_data() ++ load_benchmark_data() ++ load_benchmark_data()

    length = length(benchmark_data)

    fn ->
      Enum.at(benchmark_data, :rand.uniform(length) - 1)
    end
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
        raise "Failed to read benchmark data file"
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
        case Twm.Cache.start_link(Twm.Config.get_default()) do
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
end

# Run the benchmark when this file is executed
TwmBenchmark.run()
