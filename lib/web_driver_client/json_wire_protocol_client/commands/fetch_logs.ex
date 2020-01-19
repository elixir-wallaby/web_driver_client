defmodule WebDriverClient.JSONWireProtocolClient.Commands.FetchLogs do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  @type log_type :: JSONWireProtocolClient.log_type()

  @spec send_request(Session.t(), log_type) ::
          {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(
        %Session{id: id, config: %Config{} = config},
        log_type
      ) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/session/#{id}/log"
    request_body = %{type: log_type}

    case Tesla.post(client, url, request_body) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, jwp_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_jwp_status(jwp_response),
         {:ok, log_entries} <- ResponseParser.parse_log_entries(jwp_response) do
      {:ok, log_entries}
    end
  end
end
