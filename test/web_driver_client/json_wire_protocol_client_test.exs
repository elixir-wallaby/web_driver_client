defmodule WebDriverClient.JSONWireProtocolClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn
  import WebDriverClient.JSONWireProtocolClient.ErrorScenarios

  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.TestResponses
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData

  @moduletag :bypass
  @moduletag :capture_log
  @moduletag protocol: :jwp

  test "start_session/2 returns {:ok, %Session{}} on a valid response", %{
    bypass: bypass,
    config: config
  } do
    resp = TestResponses.start_session_response() |> pick()
    payload = build_start_session_payload()

    session_id =
      resp
      |> Jason.decode!()
      |> Map.fetch!("sessionId")

    Bypass.expect_once(bypass, "POST", "/session", fn conn ->
      conn = parse_params(conn)
      assert ^payload = conn.params

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, resp)
    end)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             JSONWireProtocolClient.start_session(payload, config)
  end

  test "start_session/2 returns {:error, %UnexpectedResponseError{}} with an unexpected response",
       %{bypass: bypass, config: config} do
    parsed_response = %{}
    payload = build_start_session_payload()

    Bypass.expect_once(bypass, "POST", "/session", fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(parsed_response))
    end)

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.start_session(payload, config)
  end

  test "start_session/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)
    payload = build_start_session_payload()

    for error_scenario <- error_scenarios() do
      %Session{config: config} =
        build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.start_session(payload, config),
        error_scenario
      )
    end
  end

  test "fetch_sessions/1 returns {:ok, [%Session{}]} on a valid response", %{
    bypass: bypass,
    config: config
  } do
    resp = TestResponses.fetch_sessions_response() |> pick()

    session_id =
      resp
      |> Jason.decode!()
      |> Map.fetch!("value")
      |> List.first()
      |> Map.fetch!("id")

    Bypass.expect_once(bypass, "GET", "/sessions", fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, resp)
    end)

    assert {:ok, [%Session{id: ^session_id, config: ^config} | _]} =
             JSONWireProtocolClient.fetch_sessions(config)
  end

  test "fetch_sessions/1 returns {:error, %UnexpectedResponseError{}} with an unexpected response",
       %{bypass: bypass, config: config} do
    parsed_response = %{}
    status = 200

    Bypass.expect_once(bypass, "GET", "/sessions", fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(status, Jason.encode!(parsed_response))
    end)

    assert {:error,
            %UnexpectedResponseError{response_body: ^parsed_response, http_status_code: ^status}} =
             JSONWireProtocolClient.fetch_sessions(config)
  end

  test "fetch_sessions/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      %Session{config: config} =
        build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.fetch_sessions(config),
        error_scenario
      )
    end
  end

  test "end_session/1 with a %Session{} uses the config on the session", %{
    bypass: bypass,
    config: config
  } do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    resp = TestResponses.end_session_response() |> pick()

    Bypass.expect_once(bypass, "DELETE", "/session/#{session_id}", fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, resp)
    end)

    assert :ok = JSONWireProtocolClient.end_session(session)
  end

  test "end_session/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.end_session(session),
        error_scenario
      )
    end
  end

  test "navigate_to/2 with valid data calls the correct url and returns the response", %{
    config: config,
    bypass: bypass
  } do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    browser_url = "http://foo.bar.example"
    resp = TestResponses.navigate_to_response() |> pick()

    Bypass.expect_once(bypass, "POST", "/session/#{session_id}/url", fn conn ->
      conn = parse_params(conn)

      assert conn.params == %{"url" => browser_url}

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, resp)
    end)

    assert :ok = JSONWireProtocolClient.navigate_to(session, browser_url)
  end

  test "navigate_to/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      url = "http://www.example.com"

      assert_expected_response(
        JSONWireProtocolClient.navigate_to(session, url),
        error_scenario
      )
    end
  end

  property "fetch_current_url/1 returns {:ok, url} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_current_url_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/url",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      url = Map.fetch!(parsed_response, "value")

      assert {:ok, ^url} = JSONWireProtocolClient.fetch_current_url(session)
    end
  end

  test "fetch_current_url/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/url",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.fetch_current_url(session)
  end

  test "fetch_current_url/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.fetch_current_url(session),
        error_scenario
      )
    end
  end

  property "fetch_window_size/1 returns {:ok, %Size{}} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_window_size_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/window/current/size",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
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

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
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
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    resp = TestResponses.set_window_size_response() |> pick()

    Bypass.expect_once(
      bypass,
      "POST",
      "/session/#{session_id}/window/current/size",
      fn conn ->
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

  property "find_element/3 sends the appropriate HTTP request", %{
    bypass: bypass,
    config: config
  } do
    check all element_location_strategy <- member_of([:css_selector, :xpath]),
              element_selector <- string(:ascii) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element",
        fn conn ->
          conn = parse_params(conn)

          expected_using_value =
            case element_location_strategy do
              :css_selector -> "css selector"
              :xpath -> "xpath"
            end

          assert %{"using" => expected_using_value, "value" => element_selector} == conn.params

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, "")
        end
      )

      JSONWireProtocolClient.find_element(session, element_location_strategy, element_selector)
    end
  end

  property "find_element/3 returns {:ok, %Element{}} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.find_element_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      element_id = get_in(parsed_response, ["value", "ELEMENT"])

      assert {:ok, %Element{id: ^element_id}} =
               JSONWireProtocolClient.find_element(session, :css_selector, "selector")
    end
  end

  test "find_element/3 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "POST",
      "/session/#{session_id}/element",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.find_element(session, :css_selector, "selector")
  end

  test "find_element/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.find_element(session, :css_selector, "selector"),
        error_scenario
      )
    end
  end

  property "find_elements/3 sends the appropriate HTTP request", %{
    bypass: bypass,
    config: config
  } do
    check all element_location_strategy <- member_of([:css_selector, :xpath]),
              element_selector <- string(:ascii) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/elements",
        fn conn ->
          conn = parse_params(conn)

          expected_using_value =
            case element_location_strategy do
              :css_selector -> "css selector"
              :xpath -> "xpath"
            end

          assert %{"using" => expected_using_value, "value" => element_selector} == conn.params

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, "")
        end
      )

      JSONWireProtocolClient.find_elements(session, element_location_strategy, element_selector)
    end
  end

  property "find_elements/3 returns {:ok, [%Element{}]} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.find_elements_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/elements",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      element_ids = parsed_response |> Map.fetch!("value") |> Enum.map(& &1["ELEMENT"])

      assert {:ok, elements} =
               JSONWireProtocolClient.find_elements(session, :css_selector, "selector")

      assert Enum.sort(element_ids) ==
               elements
               |> Enum.map(fn %Element{id: id} -> id end)
               |> Enum.sort()
    end
  end

  test "find_elements/3 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "POST",
      "/session/#{session_id}/elements",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.find_elements(session, :css_selector, "selector")
  end

  test "find_elements/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.find_elements(session, :css_selector, "selector"),
        error_scenario
      )
    end
  end

  property "find_elements_from_element/4 sends the appropriate HTTP request", %{
    bypass: bypass,
    config: config
  } do
    check all element_location_strategy <- member_of([:css_selector, :xpath]),
              element_selector <- string(:ascii) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/elements",
        fn conn ->
          conn = parse_params(conn)

          expected_using_value =
            case element_location_strategy do
              :css_selector -> "css selector"
              :xpath -> "xpath"
            end

          assert %{"using" => expected_using_value, "value" => element_selector} == conn.params

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, "")
        end
      )

      JSONWireProtocolClient.find_elements_from_element(
        session,
        element,
        element_location_strategy,
        element_selector
      )
    end
  end

  property "find_elements_from_element/4 returns {:ok, [%Element{}]} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.find_elements_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/elements",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      element_ids = parsed_response |> Map.fetch!("value") |> Enum.map(& &1["ELEMENT"])

      assert {:ok, elements} =
               JSONWireProtocolClient.find_elements_from_element(
                 session,
                 element,
                 :css_selector,
                 "selector"
               )

      assert Enum.sort(element_ids) ==
               elements
               |> Enum.map(fn %Element{id: id} -> id end)
               |> Enum.sort()
    end
  end

  test "find_elements_from_element/4 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    %Element{id: element_id} = element = TestData.element() |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "POST",
      "/session/#{session_id}/element/#{element_id}/elements",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.find_elements_from_element(
               session,
               element,
               :css_selector,
               "selector"
             )
  end

  test "find_elements_from_element/4 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()

      assert_expected_response(
        JSONWireProtocolClient.find_elements_from_element(
          session,
          element,
          :css_selector,
          "selector"
        ),
        error_scenario
      )
    end
  end

  property "fetch_log_types/1 returns {:ok, log_types} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_log_types_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/log/types",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      log_types = Map.fetch!(parsed_response, "value")

      assert {:ok, ^log_types} = JSONWireProtocolClient.fetch_log_types(session)
    end
  end

  test "fetch_log_types/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/log/types",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.fetch_log_types(session)
  end

  test "fetch_log_types/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.fetch_log_types(session),
        error_scenario
      )
    end
  end

  property "fetch_logs/2 sends the appropriate HTTP request", %{
    bypass: bypass,
    config: config
  } do
    check all log_type <- TestResponses.log_type() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/log",
        fn conn ->
          conn = parse_params(conn)

          assert %{"type" => log_type} == conn.params

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, "")
        end
      )

      JSONWireProtocolClient.fetch_logs(session, log_type)
    end
  end

  property "fetch_logs/2 returns {:ok, [LogEntry.t()]} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all log_type <- TestResponses.log_type(),
              resp <- TestResponses.fetch_logs_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/log",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      expected_log_entries =
        resp
        |> Jason.decode!()
        |> Map.fetch!("value")
        |> Enum.map(fn raw_entry ->
          %LogEntry{
            level: Map.fetch!(raw_entry, "level"),
            message: Map.fetch!(raw_entry, "message"),
            timestamp: raw_entry |> Map.fetch!("timestamp") |> DateTime.from_unix!(:millisecond),
            source: Map.get(raw_entry, "source")
          }
        end)

      assert {:ok, ^expected_log_entries} = JSONWireProtocolClient.fetch_logs(session, log_type)
    end
  end

  test "fetch_logs/2 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "POST",
      "/session/#{session_id}/log",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.fetch_logs(session, "server")
  end

  test "fetch_logs/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        JSONWireProtocolClient.fetch_logs(session, "browser"),
        error_scenario
      )
    end
  end

  property "fetch_element_displayed/2 returns {:ok, displayed} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_element_displayed_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/displayed",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      displayed? = Map.fetch!(parsed_response, "value")

      assert {:ok, ^displayed?} = JSONWireProtocolClient.fetch_element_displayed(session, element)
    end
  end

  test "fetch_element_displayed/2 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    %Element{id: element_id} = element = TestData.element() |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/element/#{element_id}/displayed",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             JSONWireProtocolClient.fetch_element_displayed(session, element)
  end

  test "fetch_element_displayed/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()

      assert_expected_response(
        JSONWireProtocolClient.fetch_element_displayed(session, element),
        error_scenario
      )
    end
  end

  defp build_start_session_payload do
    %{"defaultCapabilities" => %{"browserName" => "firefox"}}
  end
end
