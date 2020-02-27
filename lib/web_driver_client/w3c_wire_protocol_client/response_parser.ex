defmodule WebDriverClient.W3CWireProtocolClient.ResponseParser do
  @moduledoc false

  import WebDriverClient.W3CWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.Cookie
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.Response
  alias WebDriverClient.W3CWireProtocolClient.ServerStatus
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @type url :: W3CWireProtocolClient.url()

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, Response.t()} | {:error, UnexpectedResponseError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, json_body} <- parse_json(http_response) do
      {:ok, %Response{body: json_body, http_response: http_response}}
    end
  end

  # See https://w3c.github.io/webdriver/#errors
  errors = [
    {400, "element click intercepted", :element_click_intercepted},
    {400, "element not interactable", :element_not_interactable},
    {400, "insecure certificate", :insecure_certificate},
    {400, "invalid argument", :invalid_argument},
    {400, "invalid cookie domain", :invalid_cookie_domain},
    {400, "invalid element state", :invalid_element_state},
    {400, "invalid selector", :invalid_selector},
    {404, "invalid session id", :invalid_session_id},
    {500, "javascript error", :javascript_error},
    {500, "move target out of bounds", :move_target_out_of_bounds},
    {404, "no such alert", :no_such_alert},
    {404, "no such cookie", :no_such_cookie},
    {404, "no such element", :no_such_element},
    {404, "no such frame", :no_such_frame},
    {404, "no such window", :no_such_window},
    {500, "script timeout error", :script_timeout_error},
    {500, "session not created", :session_not_created},
    {404, "stale element reference", :stale_element_reference},
    {500, "timeout", :timeout},
    {500, "unable to set cookie", :unable_to_set_cookie},
    {500, "unable to capture screen", :unable_to_capture_screen},
    {500, "unexpected alert open", :unexpected_alert_open},
    {404, "unknown command", :unknown_command},
    {500, "unknown error", :unknown_error},
    {405, "unknown method", :unknown_method},
    {500, "unsupported operation", :unsupported_operation}
  ]

  @spec ensure_successful_response(Response.t()) ::
          :ok | {:error, WebDriverError.t() | UnexpectedResponseError.t()}
  def ensure_successful_response(response)

  for {status_code, error_text, error_atom} <- errors do
    def ensure_successful_response(%Response{
          http_response: %HTTPResponse{status: unquote(status_code)},
          body: %{"value" => %{"error" => unquote(error_text)} = value}
        }) do
      stacktrace = Map.get(value, "stacktrace")
      message = Map.get(value, "message")

      {:error,
       WebDriverError.exception(
         reason: unquote(error_atom),
         http_status_code: unquote(status_code),
         message: message,
         stacktrace: stacktrace
       )}
    end
  end

  def ensure_successful_response(%Response{body: body, http_response: %HTTPResponse{status: 200}})
      when is_map(body) do
    :ok
  end

  def ensure_successful_response(%Response{body: body}) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_value(Response.t()) :: {:ok, term} | {:error, UnexpectedResponseError.t()}
  def parse_value(%Response{body: %{"value" => value}}), do: {:ok, value}

  def parse_value(%Response{body: body}) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_url(Response.t()) :: {:ok, url} | {:error, UnexpectedResponseError.t()}
  def parse_url(%Response{body: body}) do
    case body do
      %{"value" => url} when is_binary(url) ->
        {:ok, url}

      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
    end
  end

  @spec parse_boolean(Response.t()) :: {:ok, boolean} | {:error, UnexpectedResponseError.t()}
  def parse_boolean(%Response{body: %{"value" => boolean}}) when is_boolean(boolean),
    do: {:ok, boolean}

  def parse_boolean(%Response{body: body}) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_log_entries(Response.t()) ::
          {:ok, [LogEntry.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_log_entries(%Response{body: body}) do
    with %{"value" => values} when is_list(values) <- body,
         log_entries when is_list(log_entries) <- do_parse_log_entries(values) do
      {:ok, log_entries}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
    end
  end

  @spec parse_rect(Response.t()) :: {:ok, Rect.t()} | {:error, UnexpectedResponseError.t()}
  def parse_rect(%Response{
        body: %{"value" => %{"width" => width, "height" => height, "x" => x, "y" => y}}
      })
      when is_integer(width) and is_integer(height) and is_integer(x) and is_integer(y) do
    {:ok, %Rect{width: width, height: height, x: x, y: y}}
  end

  def parse_rect(%Response{body: body}) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_image_data(Response.t()) :: {:ok, binary} | {:error, UnexpectedResponseError.t()}
  def parse_image_data(%Response{body: body}) do
    with %{"value" => encoded} when is_binary(encoded) <- body,
         {:ok, decoded} <- Base.decode64(encoded) do
      {:ok, decoded}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
    end
  end

  @spec parse_element(Response.t()) :: {:ok, Element.t()} | {:error, UnexpectedResponseError.t()}
  def parse_element(%Response{body: %{"value" => %{@web_element_identifier => element_id}}})
      when is_binary(element_id) do
    {:ok, %Element{id: element_id}}
  end

  def parse_element(%Response{body: body}) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
  end

  @spec parse_elements(Response.t()) ::
          {:ok, [Element.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_elements(%Response{body: body}) do
    with %{"value" => values} when is_list(values) <- body,
         elements when is_list(elements) <- do_parse_elements(values) do
      {:ok, elements}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
    end
  end

  @spec parse_cookies(Response.t()) :: {:ok, [Cookie.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_cookies(%Response{body: body}) do
    with %{"value" => values} when is_list(values) <- body,
         cookies when is_list(cookies) <- do_parse_cookies(values) do
      {:ok, cookies}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
    end
  end

  @spec parse_server_status(Response.t()) ::
          {:ok, ServerStatus.t()} | {:error, UnexpectedResponseError.t()}
  def parse_server_status(%Response{body: %{"value" => %{"ready" => ready?}}})
      when is_boolean(ready?) do
    {:ok, %ServerStatus{ready?: ready?}}
  end

  def parse_server_status(%Response{body: body}) do
    {:error, UnexpectedResponseError.exception(response_body: body)}
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

  defp do_parse_cookies(cookies) do
    cookies
    |> Enum.reduce_while([], fn
      %{"name" => name, "value" => value, "domain" => domain}, acc
      when is_binary(name) and is_binary(value) and is_binary(domain) ->
        cookie = %Cookie{
          name: name,
          value: value,
          domain: domain
        }

        {:cont, [cookie | acc]}

      _, _ ->
        {:halt, :error}
    end)
    |> case do
      :error -> :error
      cookies -> Enum.reverse(cookies)
    end
  end

  @spec parse_fetch_sessions_response(Response.t(), Config.t()) ::
          {:ok, [Session.t()]} | {:error, UnexpectedResponseError.t()}
  def parse_fetch_sessions_response(%Response{body: body}, %Config{} = config) do
    with %{"value" => values} when is_list(values) <- body,
         sessions when is_list(sessions) <- do_parse_sessions(values, config) do
      {:ok, sessions}
    else
      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
    end
  end

  @spec parse_start_session_response(Response.t(), Config.t()) ::
          {:ok, Session.t()} | {:error, UnexpectedResponseError.t()}
  def parse_start_session_response(%Response{body: body}, %Config{} = config) do
    case body do
      %{"value" => %{"sessionId" => session_id}} when is_session_id(session_id) ->
        {:ok, Session.build(session_id, config)}

      _ ->
        {:error, UnexpectedResponseError.exception(response_body: body)}
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
