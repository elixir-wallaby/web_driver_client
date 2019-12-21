defmodule WebDriverClient.JSONWireProtocolClient.Middleware.APIResponseHandler do
  @moduledoc false

  alias Tesla.Env
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

  defp parse_api_response(%Env{body: %{"value" => _value, "status" => status}} = env)
       when is_integer(status) do
    {:ok, env}
  end

  defp parse_api_response(%Env{body: body}) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end
