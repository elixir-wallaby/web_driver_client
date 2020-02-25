defmodule WebDriverClient.W3CWireProtocolClient.Commands.SetCookie do
  @moduledoc false

  import WebDriverClient.W3CWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.Cookie
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @spec send_request(Session.t(), Cookie.name(), Cookie.value(), [
          W3CWireProtocolClient.set_cookie_opt()
        ]) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}

  def send_request(%Session{id: session_id, config: %Config{} = config}, name, value, opts)
      when is_cookie_name(name) and is_cookie_value(value) and is_list(opts) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/session/#{session_id}/cookie"

    cookie_param =
      opts
      |> Keyword.take([:domain])
      |> Enum.into(%{"name" => name, "value" => value}, fn {k, v} -> {to_string(k), v} end)

    request_body = %{"cookie" => cookie_param}

    case Tesla.post(client, url, request_body) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          :ok | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, w3c_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_response(w3c_response) do
      :ok
    end
  end
end
