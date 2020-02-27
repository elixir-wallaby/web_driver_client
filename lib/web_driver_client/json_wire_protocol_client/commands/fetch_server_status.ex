defmodule WebDriverClient.JSONWireProtocolClient.Commands.FetchServerStatus do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.ServerStatus
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError

  @spec send_request(Config.t()) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(%Config{} = config) do
    client = TeslaClientBuilder.build_simple(config)

    case Tesla.get(client, "/status") do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, ServerStatus.t()} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, jwp_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_jwp_status(jwp_response),
         {:ok, server_status} <- ResponseParser.parse_server_status(jwp_response) do
      {:ok, server_status}
    end
  end
end
