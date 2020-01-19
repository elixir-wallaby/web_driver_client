defmodule WebDriverClient.Middleware.ConnectionErrorHandler do
  @moduledoc false

  alias WebDriverClient.ConnectionError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, env} ->
        {:ok, env}

      {:error, reason} when is_atom(reason) ->
        {:error, ConnectionError.exception(reason: reason)}
    end
  end
end
