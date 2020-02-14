defmodule WebDriverClient.JSONWireProtocolClient.Commands.FetchAlertText do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  @spec send_request(Session.t()) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(%Session{id: id, config: %Config{} = config}) do
    client = TeslaClientBuilder.build_simple(config)

    url = "/session/#{id}/alert_text"

    case Tesla.get(client, url) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, String.t()} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, jwp_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_jwp_status(jwp_response),
         {:ok, value} <- ResponseParser.parse_value(jwp_response) do
      {:ok, value}
    end
  end
end
