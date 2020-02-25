defmodule WebDriverClient.JSONWireProtocolClient.Commands.SetCookie do
  @moduledoc false

  import WebDriverClient.JSONWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.Cookie
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  @spec send_request(Session.t(), Cookie.name(), Cookie.value(), [
          JSONWireProtocolClient.set_cookie_opt()
        ]) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(%Session{id: id, config: %Config{} = config}, name, value, opts)
      when is_cookie_name(name) and is_cookie_value(value) and is_list(opts) do
    client = TeslaClientBuilder.build_simple(config)

    cookie_param =
      opts
      |> Keyword.take([:domain])
      |> Enum.into(%{"name" => name, "value" => value}, fn {k, v} -> {to_string(k), v} end)

    request_body = %{"cookie" => cookie_param}

    case Tesla.post(client, "/session/#{id}/cookie", request_body) do
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
