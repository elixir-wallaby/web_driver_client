defmodule WebDriverClient.W3CWireProtocolClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn
  import WebDriverClient.W3CWireProtocolClient.ErrorScenarios

  alias WebDriverClient.Element
  alias WebDriverClient.KeyCodes
  alias WebDriverClient.Session
  alias WebDriverClient.TestData
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.Cookie
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.ServerStatus
  alias WebDriverClient.W3CWireProtocolClient.TestResponses
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError

  @moduletag :bypass
  @moduletag :capture_log
  @moduletag protocol: :w3c

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  test "start_session/2 returns {:ok, %Session{}} on a valid response", %{
    bypass: bypass,
    config: config
  } do
    resp = TestResponses.start_session_response() |> pick()
    payload = build_start_session_payload()

    session_id =
      resp
      |> Jason.decode!()
      |> get_in(["value", "sessionId"])

    Bypass.expect_once(bypass, "POST", "/session", fn conn ->
      conn = parse_params(conn)
      assert ^payload = conn.params

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, resp)
    end)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             W3CWireProtocolClient.start_session(payload, config)
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
             W3CWireProtocolClient.start_session(payload, config)
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
        W3CWireProtocolClient.start_session(payload, config),
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
             W3CWireProtocolClient.fetch_sessions(config)
  end

  test "fetch_sessions/1 returns {:error, %UnexpectedResponseError{}} with an unexpected response",
       %{bypass: bypass, config: config} do
    parsed_response = %{}

    Bypass.expect_once(bypass, "GET", "/sessions", fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(parsed_response))
    end)

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_sessions(config)
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
        W3CWireProtocolClient.fetch_sessions(config),
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

    assert :ok = W3CWireProtocolClient.end_session(session)
  end

  test "end_session/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.end_session(session),
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

    assert :ok = W3CWireProtocolClient.navigate_to(session, browser_url)
  end

  test "navigate_to/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.navigate_to(session, "http://example.com"),
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

      assert {:ok, ^url} = W3CWireProtocolClient.fetch_current_url(session)
    end
  end

  test "fetch_current_url/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/url",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_current_url(session)
  end

  test "fetch_current_url/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_current_url(session),
        error_scenario
      )
    end
  end

  property "fetch_title/1 returns {:ok, title} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_title_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/title",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      title = Map.fetch!(parsed_response, "value")

      assert {:ok, ^title} = W3CWireProtocolClient.fetch_title(session)
    end
  end

  test "fetch_title/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/title",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_title(session)
  end

  test "fetch_title/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_title(session),
        error_scenario
      )
    end
  end

  property "fetch_page_source/1 returns {:ok, page_source} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_page_source_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/source",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      page_source = Map.fetch!(parsed_response, "value")

      assert {:ok, ^page_source} = W3CWireProtocolClient.fetch_page_source(session)
    end
  end

  test "fetch_page_source/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/source",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_page_source(session)
  end

  test "fetch_page_source/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_page_source(session),
        error_scenario
      )
    end
  end

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

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
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

      W3CWireProtocolClient.find_element(session, element_location_strategy, element_selector)
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
      element_id = get_in(parsed_response, ["value", @web_element_identifier])

      assert {:ok, %Element{id: ^element_id}} =
               W3CWireProtocolClient.find_element(session, :css_selector, "selector")
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
             W3CWireProtocolClient.find_element(session, :css_selector, "selector")
  end

  test "find_element/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.find_element(session, :css_selector, "selector"),
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

      W3CWireProtocolClient.find_elements(session, element_location_strategy, element_selector)
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

      element_ids =
        parsed_response |> Map.fetch!("value") |> Enum.map(& &1[@web_element_identifier])

      assert {:ok, elements} =
               W3CWireProtocolClient.find_elements(session, :css_selector, "selector")

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
             W3CWireProtocolClient.find_elements(session, :css_selector, "selector")
  end

  test "find_elements/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.find_elements(session, :css_selector, "selector"),
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

      W3CWireProtocolClient.find_elements_from_element(
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

      element_ids =
        parsed_response |> Map.fetch!("value") |> Enum.map(& &1[@web_element_identifier])

      assert {:ok, elements} =
               W3CWireProtocolClient.find_elements_from_element(
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
             W3CWireProtocolClient.find_elements_from_element(
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
        W3CWireProtocolClient.find_elements_from_element(
          session,
          element,
          :css_selector,
          "selector"
        ),
        error_scenario
      )
    end
  end

  property "fetch_active_element/1 returns {:ok, %Element{}} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_active_element_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/element/active",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      element_id = get_in(parsed_response, ["value", @web_element_identifier])

      assert {:ok, %Element{id: ^element_id}} =
               W3CWireProtocolClient.fetch_active_element(session)
    end
  end

  test "fetch_active_element/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/element/active",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_active_element(session)
  end

  test "fetch_active_element/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_active_element(session),
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
      log_types = get_in(parsed_response, ["value"])

      assert {:ok, ^log_types} = W3CWireProtocolClient.fetch_log_types(session)
    end
  end

  test "fetch_log_types/2 returns {:error, %UnexpectedResponseFormatErrror on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/log/types",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_log_types(session)
  end

  test "fetch_log_types/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_log_types(session),
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

      W3CWireProtocolClient.fetch_logs(session, log_type)
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
        |> Enum.map(fn %{"level" => level, "message" => message, "timestamp" => timestamp} ->
          %LogEntry{
            level: level,
            message: message,
            timestamp: DateTime.from_unix!(timestamp, :millisecond)
          }
        end)

      assert {:ok, ^expected_log_entries} = W3CWireProtocolClient.fetch_logs(session, log_type)
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
             W3CWireProtocolClient.fetch_logs(session, "server")
  end

  test "fetch_logs/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_logs(session, "browser"),
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

      assert {:ok, ^displayed?} = W3CWireProtocolClient.fetch_element_displayed(session, element)
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
             W3CWireProtocolClient.fetch_element_displayed(session, element)
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
        W3CWireProtocolClient.fetch_element_displayed(session, element),
        error_scenario
      )
    end
  end

  property "fetch_element_attribute/3 returns {:ok, value} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_element_attribute_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()
      attribute = TestData.attribute_name() |> pick

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/attribute/#{attribute}",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      value = Map.fetch!(parsed_response, "value")

      assert {:ok, ^value} =
               W3CWireProtocolClient.fetch_element_attribute(session, element, attribute)
    end
  end

  test "fetch_element_attribute/3 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    %Element{id: element_id} = element = TestData.element() |> pick()
    attribute = TestData.attribute_name() |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/element/#{element_id}/attribute/#{attribute}",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_element_attribute(session, element, attribute)
  end

  test "fetch_element_attribute/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()
      attribute = TestData.attribute_name() |> pick()

      assert_expected_response(
        W3CWireProtocolClient.fetch_element_attribute(session, element, attribute),
        error_scenario
      )
    end
  end

  property "fetch_element_property/3 returns {:ok, value} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_element_property_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()
      property = TestData.property_name() |> pick

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/property/#{property}",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      value = Map.fetch!(parsed_response, "value")

      assert {:ok, ^value} =
               W3CWireProtocolClient.fetch_element_property(session, element, property)
    end
  end

  test "fetch_element_property/3 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    %Element{id: element_id} = element = TestData.element() |> pick()
    property = TestData.property_name() |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/element/#{element_id}/property/#{property}",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_element_property(session, element, property)
  end

  test "fetch_element_property/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()
      property = TestData.property_name() |> pick()

      assert_expected_response(
        W3CWireProtocolClient.fetch_element_property(session, element, property),
        error_scenario
      )
    end
  end

  property "fetch_element_text/2 returns {:ok, value} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_element_text_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/text",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      value = Map.fetch!(parsed_response, "value")

      assert {:ok, ^value} = W3CWireProtocolClient.fetch_element_text(session, element)
    end
  end

  test "fetch_element_text/2 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
    %Element{id: element_id} = element = TestData.element() |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/element/#{element_id}/text",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_element_text(session, element)
  end

  test "fetch_element_text/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()

      assert_expected_response(
        W3CWireProtocolClient.fetch_element_text(session, element),
        error_scenario
      )
    end
  end

  property "click_element/2 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.click_element_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/click",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.click_element(session, element)
    end
  end

  test "click_element/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()

      assert_expected_response(
        W3CWireProtocolClient.click_element(session, element),
        error_scenario
      )
    end
  end

  property "clear_element/2 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.clear_element_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/clear",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.clear_element(session, element)
    end
  end

  test "clear_element/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()

      assert_expected_response(
        W3CWireProtocolClient.clear_element(session, element),
        error_scenario
      )
    end
  end

  property "send_keys_to_element/3 sends the proper request", %{
    bypass: bypass,
    config: config
  } do
    check all keys <-
                one_of([
                  string_to_type(),
                  valid_key_code(),
                  list_of(
                    one_of([
                      string_to_type(),
                      valid_key_code()
                    ]),
                    max_length: 10
                  )
                ]) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()

      encoded_keys =
        keys
        |> List.wrap()
        |> Enum.map(fn
          keys when is_binary(keys) ->
            keys

          keys when is_atom(keys) ->
            {:ok, encoded} = KeyCodes.encode(keys)
            encoded
        end)
        |> IO.iodata_to_binary()

      resp = "{}"

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/value",
        fn conn ->
          conn = parse_params(conn)

          assert %{"value" => encoded_keys}

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      W3CWireProtocolClient.send_keys_to_element(session, element, keys)
    end
  end

  property "send_keys_to_element/3 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.send_keys_to_element_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()
      %Element{id: element_id} = element = TestData.element() |> pick()
      value = ["hello"]

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/element/#{element_id}/value",
        fn conn ->
          conn = parse_params(conn)

          assert %{"value" => value}

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.send_keys_to_element(session, element, value)
    end
  end

  test "send_keys_to_element/3 raises an ArgumentError on unknown keystroke" do
    session = TestData.session() |> pick()
    element = TestData.element() |> pick()
    keys = [:unknown]

    assert_raise ArgumentError, ~r/unknown key code: :unknown/i, fn ->
      W3CWireProtocolClient.send_keys_to_element(session, element, keys)
    end
  end

  test "send_keys_to_element/3 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
      element = TestData.element() |> pick()
      keys = ["hello"]

      assert_expected_response(
        W3CWireProtocolClient.send_keys_to_element(session, element, keys),
        error_scenario
      )
    end
  end

  property "fetch_alert_text/1 returns {:ok, alert_text} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_alert_text_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/alert/text",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      alert_text = Map.fetch!(parsed_response, "value")

      assert {:ok, ^alert_text} = W3CWireProtocolClient.fetch_alert_text(session)
    end
  end

  test "fetch_alert_text/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/alert/text",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_alert_text(session)
  end

  test "fetch_alert_text/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_alert_text(session),
        error_scenario
      )
    end
  end

  property "accept_alert/1 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.accept_alert_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/alert/accept",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.accept_alert(session)
    end
  end

  test "accept_alert/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.accept_alert(session),
        error_scenario
      )
    end
  end

  property "dismiss_alert/1 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.dismiss_alert_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "POST",
        "/#{prefix}/session/#{session_id}/alert/dismiss",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.dismiss_alert(session)
    end
  end

  test "dismiss_alert/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.dismiss_alert(session),
        error_scenario
      )
    end
  end

  test "send_alert_text/2 with valid data calls the correct url and returns the response", %{
    config: config,
    bypass: bypass
  } do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    text = "bar"
    resp = TestResponses.send_alert_text_response() |> pick()

    Bypass.expect_once(bypass, "POST", "/session/#{session_id}/alert/text", fn conn ->
      conn = parse_params(conn)

      assert conn.params == %{"text" => text}

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, resp)
    end)

    assert :ok = W3CWireProtocolClient.send_alert_text(session, text)
  end

  test "send_alert_text/2 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.send_alert_text(session, "foo"),
        error_scenario
      )
    end
  end

  property "take_screenshot/1 returns {:ok, image_data} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.take_screenshot_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/screenshot",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      parsed_response = Jason.decode!(resp)
      image_data = parsed_response |> Map.fetch!("value") |> Base.decode64!()

      assert {:ok, ^image_data} = W3CWireProtocolClient.take_screenshot(session)
    end
  end

  test "take_screenshot/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    {config, prefix} = prefix_base_url_for_multiple_runs(config)

    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/#{prefix}/session/#{session_id}/screenshot",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.take_screenshot(session)
  end

  test "take_screenshot/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.take_screenshot(session),
        error_scenario
      )
    end
  end

  property "fetch_cookies/1 returns {:ok, [Cookie.t()]} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_cookies_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/session/#{session_id}/cookie",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      expected_cookies =
        resp
        |> Jason.decode!()
        |> Map.fetch!("value")
        |> Enum.map(fn %{"name" => name, "value" => value, "domain" => domain} ->
          %Cookie{name: name, value: value, domain: domain}
        end)

      assert {:ok, ^expected_cookies} = W3CWireProtocolClient.fetch_cookies(session)
    end
  end

  test "fetch_cookies/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/session/#{session_id}/cookie",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_cookies(session)
  end

  test "fetch_cookies/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_cookies(session),
        error_scenario
      )
    end
  end

  property "set_cookie/4 with valid data calls the correct url and returns the response", %{
    config: config,
    bypass: bypass
  } do
    cookie_name = "my_cookie"
    cookie_value = "tasty!"
    resp = TestResponses.set_cookie_response() |> pick()

    check all opts <-
                optional_map(%{domain: TestResponses.cookie_domain()}) |> map(&Keyword.new/1) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)
      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(bypass, "POST", "/#{prefix}/session/#{session_id}/cookie", fn conn ->
        conn = parse_params(conn)

        %{"cookie" => cookie_params} = conn.params

        expected_params =
          Enum.into(opts, %{"name" => cookie_name, "value" => cookie_value}, fn {k, v} ->
            {to_string(k), v}
          end)

        assert cookie_params == expected_params

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, resp)
      end)

      assert :ok = W3CWireProtocolClient.set_cookie(session, cookie_name, cookie_value, opts)
    end
  end

  test "set_cookie/4 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.set_cookie(session, "foo", "bar"),
        error_scenario
      )
    end
  end

  property "delete_cookies/1 returns :ok on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.delete_cookies_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

      Bypass.expect_once(
        bypass,
        "DELETE",
        "/#{prefix}/session/#{session_id}/cookie",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      assert :ok = W3CWireProtocolClient.delete_cookies(session)
    end
  end

  test "delete_cookies/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.delete_cookies(session),
        error_scenario
      )
    end
  end

  property "fetch_server_status/1 returns {:ok, [Cookie.t()]} on valid response", %{
    bypass: bypass,
    config: config
  } do
    check all resp <- TestResponses.fetch_server_status_response() do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      Bypass.expect_once(
        bypass,
        "GET",
        "/#{prefix}/status",
        fn conn ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp)
        end
      )

      ready? =
        resp
        |> Jason.decode!()
        |> Map.fetch!("value")
        |> Map.get("ready", true)

      assert {:ok, %ServerStatus{ready?: ^ready?}} =
               W3CWireProtocolClient.fetch_server_status(config)
    end
  end

  test "fetch_server_status/1 returns {:error, %UnexpectedResponseError{}} on invalid response",
       %{bypass: bypass, config: config} do
    parsed_response = %{}

    Bypass.expect_once(
      bypass,
      "GET",
      "/status",
      fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(parsed_response))
      end
    )

    assert {:error, %UnexpectedResponseError{response_body: ^parsed_response}} =
             W3CWireProtocolClient.fetch_server_status(config)
  end

  test "fetch_server_status/1 returns appropriate errors on various server responses", %{
    bypass: bypass,
    config: config
  } do
    scenario_server = set_up_error_scenario_tests(bypass)

    for error_scenario <- error_scenarios() do
      %Session{config: config} =
        build_session_for_scenario(scenario_server, bypass, config, error_scenario)

      assert_expected_response(
        W3CWireProtocolClient.fetch_server_status(config),
        error_scenario
      )
    end
  end

  defp build_start_session_payload do
    %{"capabilities" => %{"browserName" => "firefox"}}
  end

  defp string_to_type do
    string(:ascii, max_length: 10)
  end

  defp valid_key_code do
    KeyCodes.known_key_codes()
    |> member_of()
  end
end
