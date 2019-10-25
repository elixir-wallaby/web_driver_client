defmodule WebDriverClient.W3CWireProtocolClient do
  @moduledoc false

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.Session
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError
  alias WebDriverClient.W3CWireProtocolClient.Rect

  @spec fetch_window_rect(Session.t()) ::
          {:ok, Rect.t()}
          | {:error,
             UnexpectedResponseFormatError.t()
             | HTTPClientError.t()
             | UnexpectedStatusCodeError.t()}
  def fetch_window_rect(%Session{id: id, config: %Config{} = config})
      when is_session_id(id) do
    client = TeslaClientBuilder.build(config)
    url = "/session/#{id}/window/rect"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, rect} <- parse_rect(body) do
      {:ok, rect}
    end
  end

  @type rect_opt :: {:width, pos_integer} | {:height, pos_integer} | {:x, integer} | {:y, integer}

  @spec set_window_rect(Session.t(), [rect_opt]) ::
          :ok | {:error, HTTPClientError.t() | UnexpectedStatusCodeError.t()}
  def set_window_rect(%Session{id: id, config: %Config{} = config}, opts \\ [])
      when is_list(opts) do
    client = TeslaClientBuilder.build(config)
    url = "/session/#{id}/window/rect"
    request_body = opts |> Keyword.take([:height, :width, :x, :y]) |> Map.new()

    with {:ok, %Env{body: body}} <- Tesla.post(client, url, request_body),
         {:ok, _} <- parse_value(body) do
      :ok
    end
  end

  @spec parse_rect(term) :: {:ok, Rect.t()} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_rect(%{"value" => %{"width" => width, "height" => height, "x" => x, "y" => y}}) do
    {:ok, %Rect{width: width, height: height, x: x, y: y}}
  end

  defp parse_rect(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_value(term) :: {:ok, term} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_value(%{"value" => value}) do
    {:ok, value}
  end

  defp parse_value(body) do
    {:error, UnexpectedResponseFormatError.exception(body: body)}
  end
end
