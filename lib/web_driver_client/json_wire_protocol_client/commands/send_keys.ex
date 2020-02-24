defmodule WebDriverClient.JSONWireProtocolClient.Commands.SendKeys do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.KeyCodes
  alias WebDriverClient.Session

  @spec send_request(Session.t(), JSONWireProtocolClient.keys()) ::
          {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  def send_request(
        %Session{id: session_id, config: %Config{} = config},
        keys
      ) do
    client = TeslaClientBuilder.build_simple(config)

    request_body = %{"value" => encode(keys)}

    case Tesla.post(client, "/session/#{session_id}/keys", request_body) do
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

  defp encode(keys) do
    keys
    |> List.wrap()
    |> Enum.map(&do_encode/1)
    |> IO.iodata_to_binary()
    |> List.wrap()
  end

  defp do_encode(keys) when is_binary(keys), do: keys

  defp do_encode(keystroke) when is_atom(keystroke) do
    case KeyCodes.encode(keystroke) do
      {:ok, encoded} -> encoded
      :error -> raise ArgumentError, "unknown key code: #{inspect(keystroke)}"
    end
  end
end
