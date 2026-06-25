defmodule WebDriverClient.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :web_driver_client,
      version: @version,
      elixir: "~> 1.17",
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
      lockfile: lockfile(System.get_env("LOCKFILE")),
      docs: docs(),
      deps: deps(),
      dialyzer: dialyzer(),
      package: package(),
      description: """
      Low-level WebDriver client for Elixir.
      """
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
      {:tesla, "~> 1.3"},
      {:jason, "~> 1.0"},
      {:hackney, "~> 1.6 or ~> 4.0"},
      {:bypass, "~> 1.0 or ~> 2.1", only: :test},
      {:stream_data, "~> 0.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.20", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Allows testing against alternate dependency sets, e.g.
  # `LOCKFILE=legacy mix deps.get` for the hackney 1.x dependency set.
  # legacy.lock pins hackney 1.23.0: hackney 1.24+ discards redirect
  # response bodies read via `:hackney.body/1`, which Tesla relies on.
  defp lockfile(nil), do: "mix.lock"
  defp lockfile(""), do: "mix.lock"
  defp lockfile(lockfile), do: "test/lockfiles/#{lockfile}.lock"

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end

  defp docs do
    [
      main: "WebDriverClient",
      groups_for_modules: [
        "Main API": [
          WebDriverClient,
          WebDriverClient.Cookie,
          WebDriverClient.Config,
          WebDriverClient.ConnectionError,
          WebDriverClient.Element,
          WebDriverClient.LogEntry,
          WebDriverClient.ProtocolMismatchError,
          WebDriverClient.ServerStatus,
          WebDriverClient.Session,
          WebDriverClient.Size,
          WebDriverClient.UnexpectedResponseError,
          WebDriverClient.WebDriverError
        ],
        "Low-level JWP API": [
          WebDriverClient.JSONWireProtocolClient,
          WebDriverClient.JSONWireProtocolClient.LogEntry,
          WebDriverClient.JSONWireProtocolClient.WebDriverError,
          WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
        ],
        "Low-level W3C API": [
          WebDriverClient.W3CWireProtocolClient,
          WebDriverClient.W3CWireProtocolClient.LogEntry,
          WebDriverClient.W3CWireProtocolClient.Rect,
          WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError,
          WebDriverClient.W3CWireProtocolClient.WebDriverError
        ]
      ],
      groups_for_functions: [
        Sessions: &(&1[:subject] == :sessions),
        Navigation: &(&1[:subject] == :navigation),
        Elements: &(&1[:subject] == :elements),
        Alerts: &(&1[:subject] == :alerts),
        Logging: &(&1[:subject] == :logging)
      ],
      source_ref: "v#{@version}",
      source_url: "https://github.com/elixir-wallaby/web_driver_client"
    ]
  end

  defp package do
    [
      maintainers: ["Aaron Renner", "Michał Łępicki"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/elixir-wallaby/web_driver_client"}
    ]
  end
end
