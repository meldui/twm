defmodule Twm.MixProject do
  use Mix.Project

  @source_url "https://github.com/meldui/twm"
  @version "0.1.0"

  def project do
    [
      app: :twm,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Twm",
      source_url: "https://github.com/yourusername/twm",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    TWM (Tailwind Merge) - A Tailwind CSS class merger for Elixir.
    Merges Tailwind CSS classes without style conflicts by intelligently handling conflicting utilities.
    """
  end

  defp package do
    [
      maintainers: ["Dipayan Bhowmick"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:stream_data, "~> 0.6", only: :test}
    ]
  end
end
