defmodule WebDriverClient.JSONWireProtocolClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn
  import WebDriverClient.ErrorScenarios

  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseFormatError

  @moduletag :bypass
  @moduletag :capture_log

  property "fetch_window_size/1 returns {:ok, %Size{}} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all parsed_response <- window_size_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/window/current/size",
        fn conn ->
          resp = Jason.encode!(parsed_response)

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      width = get_in(parsed_response, ["value", "width"])
      height = get_in(parsed_response, ["value", "height"])

      assert {:ok, %Size{width: ^width, height: ^height}} =
               JSONWireProtocolClient.fetch_window_size(session)
    end
  end

  test "fetch_window_size/2 returns {:error, %UnexpectedResponseFormatErrror on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/window/current/size",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseFormatError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.fetch_window_size(session)
  end

  test "fetch_window_size/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.fetch_window_size(session),
        error_scenario
      )
    end
  end

  property "set_window_size/2 sends the appropriate HTTP request", %{
    config: config,
    bypass: bypass
  } do
    check all params <-
                optional_map(%{
                  height: integer(0..3000),
                  width: integer(0..3000)
                })
                |> map(&Keyword.new/1) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/window/current/size",
        fn conn ->
          conn = parse_params(conn)
          assert conn.params == Map.new(params, fn {key, val} -> {to_string(key), val} end)

          send_resp(conn, 200, "")
        end
      )

      JSONWireProtocolClient.set_window_size(session, params)
    end
  end

  test "set_window_size/2 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    parsed_response = %{"value" => nil}

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    Bypass.expect_once(
      bypass,
      "POST",
      "/session/#{session_id}/window/current/size",
      fn conn ->
        resp = Jason.encode!(parsed_response)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, resp)
      end
    )

    assert :ok = JSONWireProtocolClient.set_window_size(session)
  end

  test "set_window_size/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.set_window_size(session),
        error_scenario
      )
    end
  end

  defp window_size_response do
    fixed_map(%{
      "value" =>
        fixed_map(%{
          "width" => integer(0..1000),
          "height" => integer(0..1000)
        })
    })
  end
end
