defmodule WebDriverClient.JSONWireProtocolClient.ErrorScenarios do
  @moduledoc false
  use ExUnitProperties

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.JSONWireProtocolClient.ErrorScenarios.ErrorScenario
  alias WebDriverClient.JSONWireProtocolClient.ErrorScenarios.ScenarioServer
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError

  defguardp is_no_content_status_code(status_code)
            when is_integer(status_code) and status_code in [204, 304]

  defguardp is_http_success(status_code)
            when is_integer(status_code) and status_code >= 200 and status_code < 300

  @json_content_type "application/json"

  def basic_error_scenarios do
    [
      %ErrorScenario{communication_error: :server_down},
      %ErrorScenario{status_code: 500, response_body: {:other, "Internal error"}},
      %ErrorScenario{
        status_code: 200,
        content_type: @json_content_type,
        response_body: {:other, "foo"}
      }
    ]
  end

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

    Enum.concat([
      communication_error_scenarios,
      invalid_status_code_scenarios,
      invalid_json_scenarios
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
    assert {:error, %HTTPClientError{reason: :econnrefused}} = response
  end

  defp do_assert_expected_response(response, %ErrorScenario{
         communication_error: :nonexistent_domain
       }) do
    assert {:error, %HTTPClientError{reason: :nxdomain}} = response
  end

  defp do_assert_expected_response(
         response,
         %ErrorScenario{status_code: status_code} = error_scenario
       )
       when not is_http_success(status_code) do
    response_body = get_expected_body(error_scenario)

    assert {:error,
            %UnexpectedStatusCodeError{status_code: ^status_code, response_body: ^response_body}} =
             response
  end

  defp do_assert_expected_response(
         response,
         %ErrorScenario{
           content_type: @json_content_type,
           response_body: {:other, _response_body},
           status_code: status_code
         }
       )
       when not is_no_content_status_code(status_code) do
    assert {:error, %UnexpectedResponseFormatError{}} = response
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

  defp get_expected_body(%ErrorScenario{status_code: status_code})
       when is_no_content_status_code(status_code) do
    ""
  end

  defp get_expected_body(%ErrorScenario{
         content_type: @json_content_type,
         response_body: {:valid_json, parsed_body}
       }) do
    parsed_body
  end

  defp get_expected_body(%ErrorScenario{response_body: {:valid_json, parsed_body}}) do
    Jason.encode!(parsed_body)
  end

  defp get_expected_body(%ErrorScenario{response_body: {:other, body}}) do
    body
  end
end
