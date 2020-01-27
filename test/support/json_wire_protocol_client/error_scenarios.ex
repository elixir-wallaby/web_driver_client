defmodule WebDriverClient.JSONWireProtocolClient.ErrorScenarios do
  @moduledoc false
  use ExUnitProperties

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.JSONWireProtocolClient.ErrorScenarios.ErrorScenario
  alias WebDriverClient.JSONWireProtocolClient.ErrorScenarios.ScenarioServer
  alias WebDriverClient.JSONWireProtocolClient.Response.Status
  alias WebDriverClient.JSONWireProtocolClient.TestResponses
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.TestData

  defguardp is_no_content_http_status_code(http_status_code)
            when is_integer(http_status_code) and http_status_code in [204, 304]

  @json_content_type "application/json"

  def get_named_scenario(:http_client_error) do
    %ErrorScenario{communication_error: :server_down}
  end

  def get_named_scenario(:protocol_mismatch_error_web_driver_error) do
    %ErrorScenario{
      http_status_code: 400,
      content_type: @json_content_type,
      response_body: {:valid_json, %{"value" => %{"error" => "invalid selector"}}}
    }
  end

  def get_named_scenario(:unexpected_response_format) do
    %ErrorScenario{
      http_status_code: 200,
      content_type: @json_content_type,
      response_body: {:other, "foo"}
    }
  end

  def get_named_scenario(:web_driver_error) do
    %ErrorScenario{
      http_status_code: 200,
      content_type: @json_content_type,
      response_body: {:valid_json, TestResponses.jwp_response(nil, status: constant(6)) |> pick()}
    }
  end

  @basic_http_status_codes [200, 400, 500]

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
          when not is_no_content_http_status_code(http_status_code) <- @basic_http_status_codes do
        %ErrorScenario{
          http_status_code: http_status_code,
          content_type: @json_content_type,
          response_body: {:valid_json, %{"value" => nil}}
        }
      end

    invalid_jwp_status_scenarios =
      for http_status_code
          when not is_no_content_http_status_code(http_status_code) <- @basic_http_status_codes,
          jwp_status <- known_jwp_status_codes() do
        %ErrorScenario{
          http_status_code: http_status_code,
          content_type: @json_content_type,
          response_body:
            {:valid_json, TestResponses.jwp_response(nil, status: constant(jwp_status)) |> pick()}
        }
      end

    Enum.concat([
      communication_error_scenarios,
      invalid_json_scenarios,
      invalid_formatted_response_scenarios,
      invalid_jwp_status_scenarios
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
         communication_error: :nonexistent_domain
       }) do
    assert {:error, %ConnectionError{reason: :nxdomain}} = response
  end

  defp do_assert_expected_response(response, %ErrorScenario{http_status_code: 404}) do
    assert {:error, %WebDriverError{reason: :unknown_command, http_status_code: 404}} = response
  end

  defp do_assert_expected_response(
         response,
         %ErrorScenario{
           content_type: @json_content_type,
           response_body: {:valid_json, %{"value" => _, "status" => status}},
           http_status_code: http_status_code
         }
       )
       when not is_no_content_http_status_code(http_status_code) and status > 0 do
    expected_reason = Status.reason_atom(status)

    assert {:error,
            %WebDriverError{reason: ^expected_reason, http_status_code: ^http_status_code}} =
             response
  end

  defp do_assert_expected_response(
         response,
         %ErrorScenario{
           http_status_code: http_status_code
         } = error_scenario
       )
       when not is_no_content_http_status_code(http_status_code) do
    response_body = get_decoded_response_body(error_scenario)

    assert {:error,
            %UnexpectedResponseError{
              response_body: ^response_body,
              http_status_code: ^http_status_code
            }} = response
  end

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

  @known_jwp_status_codes Enum.flat_map(1..40, fn jwp_status_code ->
                            try do
                              _ = Status.reason_atom(jwp_status_code)
                              [jwp_status_code]
                            rescue
                              ArgumentError ->
                                []
                            end
                          end)

  defp known_jwp_status_codes, do: @known_jwp_status_codes
end
