defmodule WebDriverClient.W3CWireProtocolClient.ErrorScenarios do
  @moduledoc false
  use ExUnitProperties

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.JSONWireProtocolClient.TestResponses, as: JWPTestResponses
  alias WebDriverClient.TestData
  alias WebDriverClient.W3CWireProtocolClient.ErrorScenarios.ErrorScenario
  alias WebDriverClient.W3CWireProtocolClient.ErrorScenarios.ScenarioServer
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  defguardp is_no_content_status_code(status_code)
            when is_integer(status_code) and status_code in [204, 304]

  defguardp is_http_success(status_code)
            when is_integer(status_code) and status_code >= 200 and status_code < 300

  @json_content_type "application/json"

  def get_named_scenario(:http_client_error) do
    %ErrorScenario{communication_error: :server_down}
  end

  def get_named_scenario(:protocol_mismatch_error_web_driver_error) do
    %ErrorScenario{
      status_code: 400,
      content_type: @json_content_type,
      response_body:
        {:valid_json, JWPTestResponses.jwp_response(nil, status: constant(6)) |> pick()}
    }
  end

  def get_named_scenario(:web_driver_error) do
    %ErrorScenario{
      status_code: 400,
      content_type: @json_content_type,
      response_body: {:valid_json, %{"value" => %{"error" => "invalid selector"}}}
    }
  end

  def get_named_scenario(:unexpected_response_format) do
    %ErrorScenario{
      status_code: 200,
      content_type: @json_content_type,
      response_body: {:other, "foo"}
    }
  end

  # See https://w3c.github.io/webdriver/#errors
  @web_driver_errors [
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

  def error_scenarios do
    communication_error_scenarios = [
      %ErrorScenario{communication_error: :server_down},
      %ErrorScenario{communication_error: :nonexistent_domain}
    ]

    invalid_status_code_scenarios =
      for status_code when not is_http_success(status_code) <- known_status_codes(),
          content_type <- [@json_content_type, "text/plain", nil],
          response_body <- [
            {:valid_json, %{"foo" => "bar"}},
            {:other, "abc"}
          ] do
        %ErrorScenario{
          status_code: status_code,
          content_type: content_type,
          response_body: response_body
        }
      end

    invalid_json_scenarios =
      for status_code
          when is_http_success(status_code) and not is_no_content_status_code(status_code) <-
            known_status_codes() do
        %ErrorScenario{
          status_code: status_code,
          content_type: @json_content_type,
          response_body: {:other, "asdf"}
        }
      end

    web_driver_error_scenarios =
      for {status_code, error, reason_atom} <- @web_driver_errors do
        %ErrorScenario{
          status_code: status_code,
          content_type: @json_content_type,
          response_body: {:valid_json, %{"value" => %{"error" => error}}},
          web_driver_error: reason_atom
        }
      end

    Enum.concat([
      communication_error_scenarios,
      invalid_status_code_scenarios,
      invalid_json_scenarios,
      web_driver_error_scenarios
    ])
  end

  @spec build_session_for_scenario(pid, Bypass.t(), Config.t(), ErrorScenario.t()) :: Session.t()
  def build_session_for_scenario(
        scenario_server,
        %Bypass{} = bypass,
        %Config{} = config,
        %ErrorScenario{} = error_scenario
      )
      when is_pid(scenario_server) do
    reset_bypass(bypass)
    set_up_bypass_from_scenario(scenario_server, bypass, error_scenario)
    config = update_config_for_scenario(config, error_scenario)

    TestData.session(config: constant(config)) |> pick()
  end

  @spec set_up_error_scenario_tests(Bypass.t()) :: pid
  def set_up_error_scenario_tests(bypass) do
    scenario_server_pid = ExUnit.Callbacks.start_supervised!(ScenarioServer)

    Bypass.stub(bypass, :any, :any, fn conn ->
      ScenarioServer.send_scenario_resp(scenario_server_pid, conn)
    end)

    scenario_server_pid
  end

  def assert_expected_response(response, %ErrorScenario{} = scenario) do
    do_assert_expected_response(response, scenario)
  rescue
    exception ->
      stacktrace = System.stacktrace()
      reraise enhance_exception(exception, scenario, stacktrace), stacktrace
  end

  defp reset_bypass(bypass) do
    Bypass.up(bypass)
  end

  @spec set_up_bypass_from_scenario(pid, Bypass.t(), ErrorScenario.t()) :: :ok
  defp set_up_bypass_from_scenario(_scenario_server, bypass, %ErrorScenario{
         communication_error: :server_down
       }) do
    Bypass.down(bypass)
  end

  defp set_up_bypass_from_scenario(scenario_server, _bypass, %ErrorScenario{} = scenario) do
    ScenarioServer.load_scenario(scenario_server, scenario)
  end

  @spec update_config_for_scenario(Config.t(), ErrorScenario.t()) :: Config.t()
  defp update_config_for_scenario(%Config{} = config, %ErrorScenario{
         communication_error: :nonexistent_domain
       }) do
    %Config{config | base_url: "http://does.not.exist"}
  end

  defp update_config_for_scenario(%Config{} = config, %ErrorScenario{}) do
    config
  end

  defp enhance_exception(
         %AssertionError{} = original_error,
         %ErrorScenario{} = scenario,
         stacktrace
       ) do
    {exception, stacktrace} = Exception.blame(:error, original_error, stacktrace)
    formatted_exception = Exception.format_banner(:error, exception, stacktrace)

    message = """
    failed with scenario:\n\n

    #{indent(inspect(scenario, pretty: true), "    ")}\n
    got exception:\n\n#{indent(formatted_exception, "    ")}
    """

    %AssertionError{original_error | message: message}
  end

  defp enhance_exception(original_error, %ErrorScenario{}, _stacktrace) do
    original_error
  end

  defp indent(string, indentation) do
    indentation <> String.replace(string, "\n", "\n" <> indentation)
  end

  defp do_assert_expected_response(response, %ErrorScenario{communication_error: :server_down}) do
    assert {:error, %ConnectionError{reason: :econnrefused}} = response
  end

  defp do_assert_expected_response(response, %ErrorScenario{
         web_driver_error: reason_atom,
         status_code: status_code
       })
       when not is_nil(reason_atom) do
    assert {:error, %WebDriverError{reason: ^reason_atom, http_status_code: ^status_code}} =
             response
  end

  defp do_assert_expected_response(response, %ErrorScenario{
         communication_error: :nonexistent_domain
       }) do
    assert {:error, %ConnectionError{reason: :nxdomain}} = response
  end

  defp do_assert_expected_response(
         response,
         %ErrorScenario{} = error_scenario
       ) do
    response_body = get_decoded_response_body(error_scenario)

    assert {:error, %UnexpectedResponseError{response_body: ^response_body}} = response
  end

  defp get_decoded_response_body(%ErrorScenario{status_code: status_code})
       when is_no_content_status_code(status_code),
       do: ""

  defp get_decoded_response_body(%ErrorScenario{
         content_type: @json_content_type,
         response_body: {:valid_json, response_body}
       }) do
    response_body
  end

  defp get_decoded_response_body(%ErrorScenario{
         response_body: {:valid_json, response_body}
       }) do
    Jason.encode!(response_body)
  end

  defp get_decoded_response_body(%ErrorScenario{
         response_body: {:other, response_body}
       }) do
    response_body
  end

  @known_status_codes Enum.flat_map(100..599, fn status_code ->
                        try do
                          _ = Plug.Conn.Status.reason_atom(status_code)
                          [status_code]
                        rescue
                          ArgumentError ->
                            []
                        end
                      end)

  defp known_status_codes, do: @known_status_codes
end
