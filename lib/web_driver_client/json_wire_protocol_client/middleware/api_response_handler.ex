defmodule WebDriverClient.JSONWireProtocolClient.Middleware.APIResponseHandler do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.UnexpectedResponseFormatError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, %Env{} = env} ->
        parse_api_response(env)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_api_response(Env.t()) ::
          {:ok, Env.t()} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_api_response(%Env{body: body} = env) do
    with {:ok, response} <- ResponseParser.parse_response(body) do
      {:ok, %Env{env | body: response}}
    end
  end
end
