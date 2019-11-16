defmodule WebDriverClient.W3CWireProtocolClient do
  @moduledoc """
  Low-level client for W3C wire protocol.

  Use `WebDriverClient` if you'd like to support both JWP
  and W3C protocols without changing code. This module is only
  intended for use if you need W3C specific functionality.

  Specification: https://w3c.github.io/webdriver/
  """

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.Session
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect

  @type url :: String.t()

  @type basic_reason ::
          HTTPClientError.t()
          | UnexpectedResponseFormatError.t()
          | UnexpectedStatusCodeError.t()

  @doc """
  Fetches the current url of the top-level browsing context.

  Specification: https://w3c.github.io/webdriver/#get-current-url
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

  @type log_type :: String.t()

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

  This function is not part of the official spec and is
  not supported by all servers.
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
      %{"level" => level, "message" => message, "timestamp" => timestamp}, acc
      when is_binary(level) and is_binary(message) and is_integer(timestamp) ->
        log_entry = %LogEntry{
          level: level,
          message: message,
          timestamp: DateTime.from_unix!(timestamp, :millisecond)
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
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_url(term) :: {:ok, url} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_url(%{"value" => url}) do
    {:ok, url}
  end

  defp parse_url(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end
