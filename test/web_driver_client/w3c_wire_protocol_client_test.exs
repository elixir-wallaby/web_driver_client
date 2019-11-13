defmodule WebDriverClient.W3CWireProtocolClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn
  import WebDriverClient.ErrorScenarios

  alias WebDriverClient.Session
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.TestResponses

  @moduletag :bypass
  @moduletag :capture_log
  @moduletag protocol: :w3c

  property "fetch_window_rect/1 returns {:ok, %Rect} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_window_rect_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/window/rect",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      x = get_in(parsed_response, ["value", "x"])
      y = get_in(parsed_response, ["value", "y"])
      width = get_in(parsed_response, ["value", "width"])
      height = get_in(parsed_response, ["value", "height"])

      assert {:ok, %Rect{x: ^x, y: ^y, width: ^width, height: ^height}} =
               W3CWireProtocolClient.fetch_window_rect(session)
    end
  end

  test "fetch_window_rect/2 returns {:error, %UnexpectedResponseFormatErrror on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/window/rect",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseFormatError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_window_rect(session)
  end

  test "fetch_window_rect/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_window_rect(session),
        error_scenario
      )
    end
  end

  property "set_window_rect/2 sends the appropriate HTTP request", %{
    config: config,
    bypass: bypass
  } do
    check all params <-
                optional_map(%{
                  width: integer(0..1000),
                  height: integer(0..1000),
                  x: integer(),
                  y: integer()
                })
                |> map(&Keyword.new/1) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/window/rect",
        fn conn ->
          conn = parse_params(conn)
          assert conn.params == Map.new(params, fn {key, val} -> {to_string(key), val} end)

          send_resp(conn, 200, "")
        end
      )

      W3CWireProtocolClient.set_window_rect(session, params)
    end
  end

  property "set_window_rect/2 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.set_window_rect_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/window/rect",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.set_window_rect(session)
    end
  end

  test "set_window_rect/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.set_window_rect(session),
        error_scenario
      )
    end
  end
end
