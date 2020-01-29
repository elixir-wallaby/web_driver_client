defmodule WebDriverClient.JSONWireProtocolClient.Commands.FetchElementAttribute do
  @moduledoc false

  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  @spec send_request(Session.t(), Element.t(), JSONWireProtocolClient.attribute_name()) ::
          {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(
        %Session{id: session_id, config: %Config{} = config},
        %Element{id: element_id},
        attribute_name
      )
      when is_attribute_name(attribute_name) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/session/#{session_id}/element/#{element_id}/attribute/#{attribute_name}"

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
