defmodule WebDriverClient.W3CWireProtocolClient.Commands.FetchServerStatus do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.ServerStatus
  alias WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @spec send_request(Config.t()) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(%Config{} = config) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/status"

    case Tesla.get(client, url) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, ServerStatus.t()} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, w3c_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_response(w3c_response),
         {:ok, server_status} <- ResponseParser.parse_server_status(w3c_response) do
      {:ok, server_status}
    end
  end
end
