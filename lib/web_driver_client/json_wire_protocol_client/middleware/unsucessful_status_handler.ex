defmodule WebDriverClient.JSONWireProtocolClient.Middleware.UnsucessfulStatusHandler do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.JSONWireProtocolClient.Response
  alias WebDriverClient.JSONWireProtocolClient.Response.Status
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, %Env{body: %Response{status: 0}} = env} ->
        {:ok, env}

      {:ok, %Env{status: http_status_code, body: %Response{status: status}}} ->
        reason = Status.reason_atom(status)

        {:error, WebDriverError.exception(http_status_code: http_status_code, reason: reason)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
