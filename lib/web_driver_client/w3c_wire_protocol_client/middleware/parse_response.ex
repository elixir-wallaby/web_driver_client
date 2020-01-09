defmodule WebDriverClient.W3CWireProtocolClient.Middleware.ParseResponse do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @behaviour Tesla.Middleware

  @type status :: non_neg_integer()

  @impl true
  def call(env, next, _opts) do
    with {:ok, %Env{body: %HTTPResponse{} = http_response} = env} <- Tesla.run(env, next),
         {:ok, response} <- parse(http_response) do
      {:ok, %Env{env | body: response}}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec parse(HTTPResponse.t()) ::
          {:ok, map}
          | {:error, WebDriverError.t() | UnexpectedResponseError.t()}
  defp parse(%HTTPResponse{} = http_response) do
    %HTTPResponse{status: status, body: body} = http_response

    with {:ok, parsed_body} <- parse_json_body(http_response),
         :ok <- ensure_valid_w3c_status(status, parsed_body) do
      {:ok, parsed_body}
    else
      {:error, :unexpected_response} ->
        body =
          case Jason.decode(body) do
            {:ok, body} -> body
            {:error, _} -> body
          end

        error = UnexpectedResponseError.exception(response_body: body)
        {:error, error}

      {:error, %WebDriverError{} = error} ->
        {:error, error}
    end
  end

  @spec parse_json_body(HTTPResponse.t()) :: {:ok, term} | {:error, :unexpected_response}
  defp parse_json_body(%HTTPResponse{body: body}) do
    case Jason.decode(body) do
      {:ok, parsed_json} -> {:ok, parsed_json}
      {:error, _} -> {:error, :unexpected_response}
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

  @spec ensure_valid_w3c_status(status, term) ::
          :ok | {:error, WebDriverError.t() | :unexpected_response}
  defp ensure_valid_w3c_status(status, body)

  for {status_code, error_text, error_atom} <- errors do
    defp ensure_valid_w3c_status(
           unquote(status_code),
           %{"value" => %{"error" => unquote(error_text)} = value}
         ) do
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

  defp ensure_valid_w3c_status(200, parsed_body) when is_map(parsed_body) do
    :ok
  end

  defp ensure_valid_w3c_status(_status, _parsed_body) do
    {:error, :unexpected_response}
  end
end
