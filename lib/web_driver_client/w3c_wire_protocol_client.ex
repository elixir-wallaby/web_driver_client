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

  @type url :: String.t()

  @type basic_reason ::
          HTTPClientError.t()
          | UnexpectedResponseFormatError.t()
          | UnexpectedStatusCodeError.t()

  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, basic_reason}
  def fetch_current_url(%Session{id: id, config: %Config{} = config}) when is_session_id(id) do
    client = TeslaClientBuilder.build(config)
    url = "/session/#{id}/url"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, url} <- parse_url(body) do
      {:ok, url}
    end
  end

  @spec fetch_window_rect(Session.t()) :: {:ok, Rect.t()} | {:error, basic_reason}
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

  @spec set_window_rect(Session.t(), [rect_opt]) :: :ok | {:error, basic_reason}
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

  @spec parse_url(term) :: {:ok, url} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_url(%{"value" => url}) do
    {:ok, url}
  end

  defp parse_url(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end
