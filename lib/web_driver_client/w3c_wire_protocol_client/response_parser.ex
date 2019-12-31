defmodule WebDriverClient.W3CWireProtocolClient.ResponseParser do
  @moduledoc false

  import WebDriverClient.W3CWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.Session
  alias WebDriverClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect

  @type url :: W3CWireProtocolClient.url()

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  @spec parse_value(term) :: {:ok, term} | {:error, UnexpectedResponseError.t()}
  def parse_value(%{"value" => value}), do: {:ok, value}

  def parse_value(body) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_url(term) :: {:ok, url} | {:error, UnexpectedResponseError.t()}
  def parse_url(%{"value" => url}) when is_binary(url), do: {:ok, url}

  def parse_url(body) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_log_entries(term) :: {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_log_entries(response) do
    with %{"value" => values} when is_list(values) <- response,
         log_entries when is_list(log_entries) <- do_parse_log_entries(values) do
      {:ok, log_entries}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: response)}
    end
  end

  @spec parse_rect(term) :: {:ok, Rect.t()} | {:error, UnexpectedResponseError.t()}
  def parse_rect(%{"value" => %{"width" => width, "height" => height, "x" => x, "y" => y}})
      when is_integer(width) and is_integer(height) and is_integer(x) and is_integer(y) do
    {:ok, %Rect{width: width, height: height, x: x, y: y}}
  end

  def parse_rect(body) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_elements(term) :: {:ok, [Element.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_elements(response) do
    with %{"value" => values} when is_list(values) <- response,
         elements when is_list(elements) <- do_parse_elements(values) do
      {:ok, elements}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: response)}
    end
  end

  defp do_parse_elements(elements) do
    elements
    |> Enum.reduce_while([], fn
      %{@web_element_identifier => element_id}, acc
      when is_binary(element_id) ->
        element = %Element{
          id: element_id
        }

        {:cont, [element | acc]}

      _, _ ->
        {:halt, :error}
    end)
    |> case do
      :error -> :error
      element -> Enum.reverse(element)
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

  @spec parse_fetch_sessions_response(term, Config.t()) ::
          {:ok, [Session.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_fetch_sessions_response(response, %Config{} = config) do
    with %{"value" => values} when is_list(values) <- response,
         sessions when is_list(sessions) <- do_parse_sessions(values, config) do
      {:ok, sessions}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: response)}
    end
  end

  @spec parse_start_session_response(term, Config.t()) ::
          {:ok, Session.t()} | {:error, UnexpectedResponseError.t()}
  def parse_start_session_response(response, %Config{} = config) do
    case response do
      %{"value" => %{"sessionId" => session_id}} when is_session_id(session_id) ->
        {:ok, Session.build(session_id, config)}

      _ ->
        {:error, UnexpectedResponseError.exception(response_body: response)}
    end
  end

  defp do_parse_sessions(sessions, config) do
    sessions
    |> Enum.reduce_while([], fn
      %{"id" => session_id}, acc
      when is_binary(session_id) ->
        session = Session.build(session_id, config)

        {:cont, [session | acc]}

      _, _ ->
        {:halt, :error}
    end)
    |> case do
      :error -> :error
      sessions -> Enum.reverse(sessions)
    end
  end
end
