defmodule WebDriverClient.W3CWireProtocolClient.Middleware.JSONParsingErrorTranslator do
  @moduledoc false

  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    with {:error, {Tesla.Middleware.JSON, :decode, reason}} <- Tesla.run(env, next) do
      {:error, UnexpectedResponseError.exception(reason: reason)}
    end
  end
end
