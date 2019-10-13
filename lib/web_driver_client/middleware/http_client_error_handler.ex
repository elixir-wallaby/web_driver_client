defmodule WebDriverClient.Middleware.HTTPClientErrorHandler do
  @moduledoc false

  alias WebDriverClient.HTTPClientError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, env} ->
        {:ok, env}

      {:error, reason} when is_atom(reason) ->
        {:error, HTTPClientError.exception(reason: reason)}
    end
  end
end
