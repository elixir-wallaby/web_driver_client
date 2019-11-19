defmodule WebDriverClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_driver_client,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.travis": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:jason, "~> 1.0"},
      {:bypass, "~> 1.0", only: :test},
      {:hackney, "~> 1.6", only: [:dev, :test]},
      {:stream_data, "~> 0.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end
end
