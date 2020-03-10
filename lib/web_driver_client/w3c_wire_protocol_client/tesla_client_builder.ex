defmodule WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder do
  @moduledoc false
  alias Tesla.Client
  alias WebDriverClient.Config

  @spec build_simple(Config.t()) :: Client.t()
  def build_simple(%Config{
        base_url: base_url,
        debug?: debug?,
        http_client_options: http_client_options
      }) do
    adapter = {Tesla.Adapter.Hackney, http_client_options}

    middleware =
      [
        {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.EncodeJson,
        WebDriverClient.Middleware.ConnectionErrorHandler,
        Tesla.Middleware.Logger
      ]
      |> Enum.reject(fn
        Tesla.Middleware.Logger -> !debug?
        _ -> false
      end)

    Tesla.client(middleware, adapter)
  end
end
