defmodule WebDriverClient.APIClientCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Plug.Conn
  alias Plug.Parsers

  alias WebDriverClient.Config

  setup [:start_bypass, :set_config_from_bypass]

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  def bypass_url(%Bypass{port: port}, path \\ "") do
    "http://localhost:#{port}" |> URI.merge(path) |> to_string()
  end

  defp set_config_from_bypass(%{bypass: %Bypass{} = bypass}) do
    [config: config_from_bypass(bypass)]
  end

  defp config_from_bypass(%Bypass{} = bypass) do
    Config.build(base_url: bypass_url(bypass))
  end

  defp start_bypass(%{bypass: true}) do
    {:ok, bypass: Bypass.open()}
  end

  defp start_bypass(_), do: :ok

  def parse_params(%Conn{} = conn) do
    Parsers.call(conn, Parsers.init(parsers: [:json], json_decoder: Jason))
  end
end
