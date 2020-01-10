defmodule WebDriverClient.JSONWireProtocolClient.Middleware.ParseJSON do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError

  @behaviour Tesla.Middleware

  @json_content_type "application/json"

  @impl true
  def call(env, next, _opts) do
    with {:ok, env} <- Tesla.run(env, next),
         {:ok, parsed_json} <- parse_json(env) do
      {:ok, %Env{env | body: parsed_json}}
    end
  end

  defp parse_json(%Env{body: body} = env) do
    with :ok <- ensure_json_content_type(env),
         {:ok, json} <- Jason.decode(body) do
      {:ok, json}
    else
      {:error, reason} ->
        {:error, UnexpectedResponseError.exception(reason: reason, response_body: body)}
    end
  end

  @spec ensure_json_content_type(Env.t()) :: :ok | {:error, :no_json_content_type}
  defp ensure_json_content_type(%Env{} = env) do
    with content_type when is_binary(content_type) <- Tesla.get_header(env, "content-type"),
         true <- String.starts_with?(content_type, @json_content_type) do
      :ok
    else
      _ ->
        {:error, :no_json_content_type}
    end
  end
end
