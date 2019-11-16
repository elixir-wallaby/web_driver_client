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
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
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

  @type log_type :: String.t()

  @doc """
  Fetches the available log types.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlogtypes
  """
  @doc subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [log_type]} | {:error, basic_reason()}
  def fetch_log_types(%Session{id: id, config: %Config{} = config}) do
    client = TeslaClientBuilder.build(config)
    url = "/session/#{id}/log/types"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, log_types} <- parse_value(body) do
      {:ok, log_types}
    end
  end

  @doc """
  Fetches the log for a given type.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlog
  """
  @doc subject: :logging
  @spec fetch_logs(Session.t(), log_type) :: {:ok, [LogEntry.t()]} | {:error, basic_reason()}
  def fetch_logs(%Session{id: id, config: %Config{} = config}, log_type) do
    client = TeslaClientBuilder.build(config)
    url = "/session/#{id}/log"
    request_body = %{type: log_type}

    with {:ok, %Env{body: body}} <- Tesla.post(client, url, request_body),
         {:ok, logs} <- parse_log_entries(body) do
      {:ok, logs}
    end
  end

  @spec parse_log_entries(term) ::
          {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_log_entries(response) do
    with %{"value" => values} when is_list(values) <- response,
         log_entries when is_list(log_entries) <- do_parse_log_entries(values) do
      {:ok, log_entries}
    else
      _ ->
        {:error, UnexpectedResponseFormatError.exception(response_body: response)}
    end
  end

  defp do_parse_log_entries(log_entries) do
    log_entries
    |> Enum.reduce_while([], fn
      %{"level" => level, "message" => message, "timestamp" => timestamp} = raw_entry, acc
      when is_binary(level) and is_binary(message) and is_integer(timestamp) ->
        log_entry = %LogEntry{
          level: level,
          message: message,
          timestamp: DateTime.from_unix!(timestamp, :millisecond),
          source: Map.get(raw_entry, "source")
        }

        {:cont, [log_entry | acc]}

      _, _ ->
        {:halt, :error}
    end)
    |> case do
      :error -> :error
      log_entries -> Enum.reverse(log_entries)
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
