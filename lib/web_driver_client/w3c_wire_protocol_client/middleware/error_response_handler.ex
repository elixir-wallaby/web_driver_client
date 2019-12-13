defmodule WebDriverClient.W3CWireProtocolClient.Middleware.ErrorResponseHandler do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, %Env{} = env} ->
        parse_error(env)

      {:error, reason} ->
        {:error, reason}
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

  @spec parse_error(Env.t()) ::
          {:ok, Env.t()} | {:error, WebDriverError.t() | UnexpectedResponseFormatError.t()}
  defp parse_error(env)

  for {status_code, error_text, error_atom} <- errors do
    defp parse_error(%Env{
           status: unquote(status_code),
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

  defp parse_error(%Env{status: 200, body: body} = env) when is_map(body) do
    {:ok, env}
  end

  defp parse_error(%Env{body: body}) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end
