defmodule WebDriverClient.W3CWireProtocolClient.Commands.SendKeysToElement do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.KeyCodes
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @spec send_request(Session.t(), Element.t(), W3CWireProtocolClient.keys()) ::
          {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}

  def send_request(
        %Session{id: session_id, config: %Config{} = config},
        %Element{id: element_id},
        keys
      ) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/session/#{session_id}/element/#{element_id}/value"

    request_body = %{"text" => encode(keys)}

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

  defp encode(keys) do
    keys
    |> List.wrap()
    |> Enum.map(&do_encode/1)
    |> IO.iodata_to_binary()
  end

  defp do_encode(keys) when is_binary(keys), do: keys

  defp do_encode(keystroke) when is_atom(keystroke) do
    case KeyCodes.encode(keystroke) do
      {:ok, encoded} -> encoded
      :error -> raise ArgumentError, "unknown key code: #{inspect(keystroke)}"
    end
  end
end
