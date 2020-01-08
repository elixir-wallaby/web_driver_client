defmodule WebDriverClient.Middleware.HTTPResponseBuilder do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.HTTPResponse

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, env} ->
        {:ok, %Env{env | body: to_http_response(env)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec to_http_response(Env.t()) :: HTTPResponse.t()
  defp to_http_response(%Env{} = env) do
    %Env{
      status: status,
      headers: headers,
      body: body
    } = env

    %HTTPResponse{status: status, headers: headers, body: body}
  end
end
