defmodule WebDriverClient.JSONWireProtocolClient.Commands.StartSession do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  @spec send_request(Config.t(), map) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(%Config{} = config, payload) when is_map(payload) do
    client = TeslaClientBuilder.build_simple(config)

    case Tesla.post(client, "/session", payload) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t(), Config.t()) ::
          {:ok, Session.t()} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response, %Config{} = config) do
    with {:ok, jwp_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_jwp_status(jwp_response),
         {:ok, session} <- ResponseParser.parse_start_session_response(jwp_response, config) do
      {:ok, session}
    end
  end
end
