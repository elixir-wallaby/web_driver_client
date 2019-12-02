defmodule WebDriverClient.JSONWireProtocolClient.ResponseParser do
  @moduledoc false

  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.Size
  alias WebDriverClient.UnexpectedResponseFormatError

  @spec parse_value(term) :: {:ok, term} | {:error, UnexpectedResponseFormatError.t()}
  def parse_value(%{"value" => value}) do
    {:ok, value}
  end

  def parse_value(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_url(term) ::
          {:ok, JSONWireProtocolClient.url()} | {:error, UnexpectedResponseFormatError.t()}
  def parse_url(%{"value" => url}) when is_binary(url) do
    {:ok, url}
  end

  def parse_url(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_log_entries(term) ::
          {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseFormatError.t()}
  def parse_log_entries(response) do
    with %{"value" => values} when is_list(values) <- response,
         log_entries when is_list(log_entries) <- do_parse_log_entries(values) do
      {:ok, log_entries}
    else
      _ ->
        {:error, UnexpectedResponseFormatError.exception(response_body: response)}
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

  @spec parse_size(term) :: {:ok, Size.t()} | {:error, UnexpectedResponseFormatError.t()}
  def parse_size(%{"value" => %{"width" => width, "height" => height}})
      when is_integer(width) and is_integer(height) do
    {:ok, %Size{width: width, height: height}}
  end

  def parse_size(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end
