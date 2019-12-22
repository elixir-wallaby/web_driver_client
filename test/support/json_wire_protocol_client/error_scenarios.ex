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

  defguardp is_no_content_http_status_code(http_status_code)
            when is_integer(http_status_code) and http_status_code in [204, 304]

  @json_content_type "application/json"

  def basic_error_scenarios do
    [
      %ErrorScenario{communication_error: :server_down},
      %ErrorScenario{http_status_code: 500, response_body: {:other, "Internal error"}},
      %ErrorScenario{
        http_status_code: 200,
        content_type: @json_content_type,
        response_body: {:other, "foo"}
      },
      # Missing status
      %ErrorScenario{
        http_status_code: 200,
        content_type: @json_content_type,
        response_body: {:valid_json, %{"value" => nil}}
      }
    ]
  end

  def error_scenarios do
    communication_error_scenarios = [
      %ErrorScenario{communication_error: :server_down},
      %ErrorScenario{communication_error: :nonexistent_domain}
    ]

    invalid_json_scenarios =
      for http_status_code
          when not is_no_content_http_status_code(http_status_code) <- known_http_status_codes() do
        %ErrorScenario{
          http_status_code: http_status_code,
          content_type: @json_content_type,
          response_body: {:other, "asdf"}
        }
      end

    invalid_formatted_response_scenarios =
      for http_status_code
          when not is_no_content_http_status_code(http_status_code) <- known_http_status_codes() do
        %ErrorScenario{
          http_status_code: http_status_code,
          content_type: @json_content_type,
          response_body: {:valid_json, %{"value" => nil}}
        }
      end

    Enum.concat([
      communication_error_scenarios,
      invalid_json_scenarios,
      invalid_formatted_response_scenarios
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
         %ErrorScenario{
           http_status_code: http_status_code
         }
       )
       when not is_no_content_http_status_code(http_status_code) do
    assert {:error, %UnexpectedResponseFormatError{}} = response
  end

  defp do_assert_expected_response(
         response,
         %ErrorScenario{
           content_type: @json_content_type,
           response_body: {:valid_json, response_body},
           http_status_code: http_status_code
         }
       )
       when not is_no_content_http_status_code(http_status_code) do
    assert {:error, %UnexpectedResponseFormatError{response_body: ^response_body}} = response
  end

  @known_http_status_codes Enum.flat_map(100..599, fn http_status_code ->
                             try do
                               _ = Plug.Conn.Status.reason_atom(http_status_code)
                               [http_status_code]
                             rescue
                               ArgumentError ->
                                 []
                             end
                           end)

  defp known_http_status_codes, do: @known_http_status_codes
end
