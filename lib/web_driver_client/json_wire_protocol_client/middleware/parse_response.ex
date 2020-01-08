defmodule WebDriverClient.JSONWireProtocolClient.Middleware.ParseResponse do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient.Response
  alias WebDriverClient.JSONWireProtocolClient.Response.Status
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    with {:ok, %Env{body: %HTTPResponse{} = http_response} = env} <- Tesla.run(env, next),
         {:ok, response} <- parse(http_response) do
      {:ok, %Env{env | body: response}}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec parse(HTTPResponse.t()) ::
          {:ok, Response.t()}
          | {:error, WebDriverError.t() | UnexpectedResponseError.t()}
  defp parse(%HTTPResponse{} = http_response) do
    %HTTPResponse{status: status, body: body} = http_response

    with {:ok, parsed_body} <- parse_json_body(http_response),
         {:ok, response} <- parse_jwp_response(parsed_body),
         :ok <- ensure_valid_jwp_status(response) do
      {:ok, response}
    else
      {:error, :unexpected_response} ->
        body =
          case Jason.decode(body) do
            {:ok, body} -> body
            {:error, _} -> body
          end

        error = UnexpectedResponseError.exception(response_body: body)
        {:error, error}

      {:error, {:invalid_status, reason}} ->
        error =
          WebDriverError.exception(
            http_status_code: status,
            reason: reason
          )

        {:error, error}
    end
  end

  @spec parse_json_body(HTTPResponse.t()) :: {:ok, term} | {:error, :unexpected_response}
  defp parse_json_body(%HTTPResponse{body: body}) do
    case Jason.decode(body) do
      {:ok, parsed_json} -> {:ok, parsed_json}
      {:error, _} -> {:error, :unexpected_response}
    end
  end

  @spec parse_jwp_response(term) :: {:ok, Response.t()} | {:error, :unexpected_response}
  def parse_jwp_response(parsed_response_body) do
    case ResponseParser.parse_response(parsed_response_body) do
      {:ok, response} ->
        {:ok, response}

      {:error, %UnexpectedResponseError{}} ->
        {:error, :unexpected_response}
    end
  end

  @spec ensure_valid_jwp_status(Response.t()) :: :ok | {:error, {:invalid_status, atom}}
  defp ensure_valid_jwp_status(%Response{status: 0}), do: :ok

  defp ensure_valid_jwp_status(%Response{status: status}) do
    reason = Status.reason_atom(status)

    {:error, {:invalid_status, reason}}
  end
end
