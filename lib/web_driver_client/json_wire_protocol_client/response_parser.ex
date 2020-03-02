defmodule WebDriverClient.JSONWireProtocolClient.ResponseParser do
  @moduledoc false

  import WebDriverClient.JSONWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.Cookie
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.Response
  alias WebDriverClient.JSONWireProtocolClient.Response.Status
  alias WebDriverClient.JSONWireProtocolClient.Size
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session

  defguardp is_status(term) when is_integer(term) and term >= 0

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, Response.t()} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{status: 404}) do
    {:error, WebDriverError.exception(http_status_code: 404, reason: :unknown_command)}
  end

  def parse_response(%HTTPResponse{body: body} = http_response) when is_binary(body) do
    with {:ok, %{"value" => value, "status" => status} = body} when is_status(status) <-
           parse_json(http_response),
         session_id when is_session_id(session_id) or is_nil(session_id) <-
           Map.get(body, "sessionId") do
      {:ok,
       %Response{
         session_id: session_id,
         status: status,
         value: value,
         http_response: http_response
       }}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
    end
  end

  # This clause will eventually go away once everything is
  # migrate to the command pattern
  def parse_response(%HTTPResponse{body: body} = http_response) do
    with %{"value" => value, "status" => status} when is_status(status) <- body,
         session_id when is_session_id(session_id) or is_nil(session_id) <-
           Map.get(body, "sessionId") do
      {:ok,
       %Response{
         session_id: session_id,
         status: status,
         value: value,
         http_response: http_response
       }}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
    end
  end

  @spec ensure_successful_jwp_status(Response.t()) :: :ok | {:error, WebDriverError.t()}
  def ensure_successful_jwp_status(%Response{status: 0}), do: :ok

  def ensure_successful_jwp_status(%Response{} = response) do
    %Response{
      status: status,
      http_response: %HTTPResponse{
        status: http_status_code
      }
    } = response

    reason = Status.reason_atom(status)

    {:error, WebDriverError.exception(http_status_code: http_status_code, reason: reason)}
  end

  @spec parse_value(Response.t()) :: {:ok, term}
  def parse_value(%Response{value: value}) do
    {:ok, value}
  end

  @spec parse_boolean(Response.t()) :: {:ok, boolean} | {:error, UnexpectedResponseError.t()}
  def parse_boolean(%Response{value: boolean}) when is_boolean(boolean) do
    {:ok, boolean}
  end

  def parse_boolean(%Response{http_response: http_response}) do
    {:error, build_unexpected_response_error(http_response)}
  end

  @spec parse_url(Response.t()) ::
          {:ok, JSONWireProtocolClient.url()} | {:error, UnexpectedResponseError.t()}
  def parse_url(%Response{value: url}) when is_binary(url) do
    {:ok, url}
  end

  def parse_url(%Response{http_response: http_response}) do
    {:error, build_unexpected_response_error(http_response)}
  end

  @spec parse_log_entries(Response.t()) ::
          {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_log_entries(%Response{value: value, http_response: http_response}) do
    with values when is_list(values) <- value,
         log_entries when is_list(log_entries) <- do_parse_log_entries(values) do
      {:ok, log_entries}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
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
  def parse_elements(%Response{value: value, http_response: http_response}) do
    with values when is_list(values) <- value,
         elements when is_list(elements) <- do_parse_elements(values) do
      {:ok, elements}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
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

  @spec parse_element(Response.t()) :: {:ok, Element.t()} | {:error, UnexpectedResponseError.t()}
  def parse_element(%Response{value: %{"ELEMENT" => element_id}}) when is_binary(element_id) do
    {:ok, %Element{id: element_id}}
  end

  def parse_element(%Response{http_response: http_response}) do
    {:error, build_unexpected_response_error(http_response)}
  end

  @spec parse_fetch_sessions_response(Response.t(), Config.t()) ::
          {:ok, [Session.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_fetch_sessions_response(
        %Response{value: value, http_response: http_response},
        %Config{} = config
      ) do
    with values when is_list(values) <- value,
         sessions when is_list(sessions) <- do_parse_sessions(values, config) do
      {:ok, sessions}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
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

  def parse_size(%Response{http_response: http_response}) do
    {:error, build_unexpected_response_error(http_response)}
  end

  @spec parse_image_data(Response.t()) :: {:ok, binary} | {:error, UnexpectedResponseError.t()}
  def parse_image_data(%Response{value: value, http_response: http_response}) do
    with encoded when is_binary(encoded) <- value,
         {:ok, decoded} <- Base.decode64(encoded) do
      {:ok, decoded}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
    end
  end

  @spec parse_cookies(Response.t()) :: {:ok, [Cookie.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_cookies(%Response{value: value, http_response: http_response}) do
    with values when is_list(values) <- value,
         cookies when is_list(cookies) <- do_parse_cookies(values) do
      {:ok, cookies}
    else
      _ ->
        {:error, build_unexpected_response_error(http_response)}
    end
  end

  def do_parse_cookies(cookies) do
    cookies
    |> Enum.reduce_while([], fn
      %{"name" => name, "value" => value, "domain" => domain}, acc
      when is_binary(name) and is_binary(value) and is_binary(domain) ->
        cookie = %Cookie{name: name, value: value, domain: domain}

        {:cont, [cookie | acc]}

      _, _ ->
        {:halt, :error}
    end)
    |> case do
      :error -> :error
      cookies -> Enum.reverse(cookies)
    end
  end

  @spec build_unexpected_response_error(HTTPResponse.t()) :: UnexpectedResponseError.t()
  defp build_unexpected_response_error(%HTTPResponse{status: status, body: body}) do
    UnexpectedResponseError.exception(response_body: body, http_status_code: status)
  end

  @json_content_type "application/json"

  defp parse_json(%HTTPResponse{body: body, status: status} = http_response) do
    with :ok <- ensure_json_content_type(http_response),
         {:ok, json} <- Jason.decode(body) do
      {:ok, json}
    else
      {:error, reason} ->
        {:error,
         UnexpectedResponseError.exception(
           reason: reason,
           response_body: body,
           http_status_code: status
         )}
    end
  end

  @spec ensure_json_content_type(HTTPResponse.t()) :: :ok | {:error, :no_json_content_type}
  defp ensure_json_content_type(%HTTPResponse{} = http_response) do
    with content_type when is_binary(content_type) <- get_header(http_response, "content-type"),
         true <- String.starts_with?(content_type, @json_content_type) do
      :ok
    else
      _ ->
        {:error, :no_json_content_type}
    end
  end

  @spec get_header(HTTPResponse.t(), binary) :: binary | nil
  defp get_header(%HTTPResponse{headers: headers}, key) do
    case List.keyfind(headers, key, 0) do
      {_, value} -> value
      _ -> nil
    end
  end
end
