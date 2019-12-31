defmodule WebDriverClient.JSONWireProtocolClient.ResponseParser do
  @moduledoc false

  import WebDriverClient.JSONWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.Response
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.UnexpectedResponseError

  defguardp is_status(term) when is_integer(term) and term >= 0

  @spec parse_response(term) :: {:ok, Response.t()} | {:error, UnexpectedResponseError.t()}
  def parse_response(term) do
    with %{"value" => value, "status" => status} when is_status(status) <- term,
         session_id when is_session_id(session_id) or is_nil(session_id) <-
           Map.get(term, "sessionId") do
      {:ok, %Response{session_id: session_id, status: status, value: value, original_body: term}}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: term)}
    end
  end

  @spec parse_value(Response.t()) :: {:ok, term}
  def parse_value(%Response{value: value}) do
    {:ok, value}
  end

  @spec parse_url(Response.t()) ::
          {:ok, JSONWireProtocolClient.url()} | {:error, UnexpectedResponseError.t()}
  def parse_url(%Response{value: url}) when is_binary(url) do
    {:ok, url}
  end

  def parse_url(%Response{original_body: original_body}) do
    {:error, UnexpectedResponseError.exception(response_body: original_body)}
  end

  @spec parse_log_entries(Response.t()) ::
          {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_log_entries(%Response{value: value, original_body: original_body}) do
    with values when is_list(values) <- value,
         log_entries when is_list(log_entries) <- do_parse_log_entries(values) do
      {:ok, log_entries}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: original_body)}
    end
  end

  def do_parse_log_entries(log_entries) do
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

  @spec parse_elements(Response.t()) ::
          {:ok, [Element.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_elements(%Response{value: value, original_body: original_body}) do
    with values when is_list(values) <- value,
         elements when is_list(elements) <- do_parse_elements(values) do
      {:ok, elements}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: original_body)}
    end
  end

  defp do_parse_elements(elements) do
    elements
    |> Enum.reduce_while([], fn
      %{"ELEMENT" => element_id}, acc
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

  @spec parse_fetch_sessions_response(Response.t(), Config.t()) ::
          {:ok, [Session.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_fetch_sessions_response(
        %Response{value: value, original_body: original_body},
        %Config{} = config
      ) do
    with values when is_list(values) <- value,
         sessions when is_list(sessions) <- do_parse_sessions(values, config) do
      {:ok, sessions}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: original_body)}
    end
  end

  @spec parse_start_session_response(Response.t(), Config.t()) :: {:ok, Session.t()}
  def parse_start_session_response(
        %Response{session_id: session_id},
        %Config{} = config
      ) do
    {:ok, Session.build(session_id, config)}
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

  @spec parse_size(Response.t()) :: {:ok, Size.t()} | {:error, UnexpectedResponseError.t()}
  def parse_size(%Response{value: %{"width" => width, "height" => height}})
      when is_integer(width) and is_integer(height) do
    {:ok, %Size{width: width, height: height}}
  end

  def parse_size(%Response{original_body: original_body}) do
    {:error, UnexpectedResponseError.exception(response_body: original_body)}
  end
end
