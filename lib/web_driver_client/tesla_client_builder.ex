defmodule WebDriverClient.TeslaClientBuilder do
  @moduledoc false
  alias Tesla.Client
  alias WebDriverClient.Config

  @spec build(Config.t()) :: Client.t()
  def build(%Config{base_url: base_url}) do
    adapter = Tesla.Adapter.Hackney

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      WebDriverClient.Middleware.JSONParsingErrorTranslator,
      Tesla.Middleware.JSON,
      WebDriverClient.Middleware.UnexpectedStatusCodeErrorHandler,
      WebDriverClient.Middleware.HTTPClientErrorHandler,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware, adapter)
  end
end
