defmodule WebDriverClient.JSONWireProtocolClient do
  @moduledoc """
  Low-level client for JSON wire protocol (JWP).

  Use `WebDriverClient` if you'd like to support both JWP
  and W3C protocols without changing code. This module is only
  intended for use if you need JWP specific functionality.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
  """

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError

  @type url :: String.t()

  @type basic_reason ::
          HTTPClientError.t()
          | UnexpectedResponseFormatError.t()
          | UnexpectedStatusCodeError.t()

  @doc """
  Fetches the url of the current page.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidurl
  """
  @doc subject: :navigation
  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, basic_reason}
  def fetch_current_url(%Session{id: id, config: %Config{} = config}) when is_session_id(id) do
    client = TeslaClientBuilder.build(config)

    url = "/session/#{id}/url"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, url} <- parse_url(body) do
      {:ok, url}
    end
  end

  @spec fetch_window_size(Session.t()) :: {:ok, Size.t()} | {:error, basic_reason}
  def fetch_window_size(%Session{id: id, config: %Config{} = config})
      when is_session_id(id) do
    client = TeslaClientBuilder.build(config)
    window_handle = "current"

    url = "/session/#{id}/window/#{window_handle}/size"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, size} <- parse_size(body) do
      {:ok, size}
    end
  end

  @type size_opt :: {:width, pos_integer} | {:height, pos_integer}

  @spec set_window_size(Session.t(), [size_opt]) :: :ok | {:error, basic_reason}
  def set_window_size(%Session{id: id, config: %Config{} = config}, opts \\ [])
      when is_list(opts) do
    window_handle = "current"
    url = "/session/#{id}/window/#{window_handle}/size"

    request_body = opts |> Keyword.take([:height, :width]) |> Map.new()

    config
    |> TeslaClientBuilder.build()
    |> Tesla.post(url, request_body)
    |> case do
      {:ok, %Env{}} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches the available log types.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlogtypes
  """
  @doc subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [String.t()]} | {:error, basic_reason()}
  def fetch_log_types(%Session{id: id, config: %Config{} = config}) do
    client = TeslaClientBuilder.build(config)
    url = "/session/#{id}/log/types"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, log_types} <- parse_value(body) do
      {:ok, log_types}
    end
  end

  @spec parse_size(term) :: {:ok, Size.t()} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_size(%{"value" => %{"width" => width, "height" => height}}) do
    {:ok, %Size{width: width, height: height}}
  end

  defp parse_size(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_url(term) :: {:ok, url} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_url(%{"value" => url}) do
    {:ok, url}
  end

  defp parse_url(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_value(term) :: {:ok, term} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_value(%{"value" => value}) do
    {:ok, value}
  end

  defp parse_value(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end
