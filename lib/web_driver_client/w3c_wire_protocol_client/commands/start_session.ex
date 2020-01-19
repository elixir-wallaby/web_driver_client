defmodule WebDriverClient.W3CWireProtocolClient.Commands.StartSession do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @spec send_request(Config.t(), map) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}

  def send_request(
        %Config{} = config,
        payload
      )
      when is_map(payload) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/session"

    case Tesla.post(client, url, payload) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t(), Config.t()) ::
          {:ok, Session.t()} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response, %Config{} = config) do
    with {:ok, w3c_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_response(w3c_response),
         {:ok, session} <- ResponseParser.parse_start_session_response(w3c_response, config) do
      {:ok, session}
    end
  end
end
