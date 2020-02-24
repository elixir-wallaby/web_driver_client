defmodule WebDriverClient.JSONWireProtocolClient.Commands.SendAlertText do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  @spec send_request(Session.t(), String.t()) ::
          {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(%Session{id: session_id, config: %Config{} = config}, text)
      when is_binary(text) do
    client = TeslaClientBuilder.build_simple(config)

    request_body = %{"text" => text}

    case Tesla.post(client, "/session/#{session_id}/alert_text", request_body) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          :ok | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, jwp_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_jwp_status(jwp_response) do
      :ok
    end
  end
end
