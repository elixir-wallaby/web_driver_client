defmodule WebDriverClient.W3CWireProtocolClient.ResponseParser do
  @moduledoc false

  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect

  @type url :: W3CWireProtocolClient.url()

  @spec parse_value(term) :: {:ok, term} | {:error, UnexpectedResponseFormatError.t()}
  def parse_value(%{"value" => value}), do: {:ok, value}

  def parse_value(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end

  @spec parse_url(term) :: {:ok, url} | {:error, UnexpectedResponseFormatError.t()}
  def parse_url(%{"value" => url}) when is_binary(url), do: {:ok, url}

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

  @spec parse_rect(term) :: {:ok, Rect.t()} | {:error, UnexpectedResponseFormatError.t()}
  def parse_rect(%{"value" => %{"width" => width, "height" => height, "x" => x, "y" => y}})
      when is_integer(width) and is_integer(height) and is_integer(x) and is_integer(y) do
    {:ok, %Rect{width: width, height: height, x: x, y: y}}
  end

  def parse_rect(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
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
end
