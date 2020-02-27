defmodule WebDriverClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn

  alias WebDriverClient.ConnectionError
  alias WebDriverClient.Cookie
  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient.ErrorScenarios, as: JWPErrorScenarios
  alias WebDriverClient.JSONWireProtocolClient.TestResponses, as: JWPTestResponses
  alias WebDriverClient.LogEntry
  alias WebDriverClient.ProtocolMismatchError
  alias WebDriverClient.ServerStatus
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.ErrorScenarios, as: W3CErrorScenarios
  alias WebDriverClient.W3CWireProtocolClient.TestResponses, as: W3CTestResponses
  alias WebDriverClient.WebDriverError

  @moduletag :bypass
  @moduletag :capture_log

  @protocols [:jwp, :w3c]

  @tag protocol: :jwp
  test "start_session/2 with JWP config returns {:ok, Session.t()} with a valid response", %{
    config: config,
    bypass: bypass
  } do
    resp = JWPTestResponses.start_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Session{config: ^config}} =
             WebDriverClient.start_session(config, build_start_session_payload())
  end

  @tag protocol: :w3c
  test "start_session/2 with W3C config returns {:ok, Session.t()} with a valid response", %{
    config: config,
    bypass: bypass
  } do
    resp = W3CTestResponses.start_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Session{config: ^config}} =
             WebDriverClient.start_session(config, build_start_session_payload())
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "start_session/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        %Session{config: config} =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.start_session(config, build_start_session_payload()),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_sessions/1 with jwp session returns {:ok, %Session{}] on success", %{
    config: config,
    bypass: bypass
  } do
    resp = JWPTestResponses.fetch_sessions_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, sessions} = WebDriverClient.fetch_sessions(config)
    assert Enum.all?(sessions, &match?(%Session{config: ^config}, &1))
  end

  @tag protocol: :w3c
  test "fetch_sessions/1 with w3c session returns {:ok, %Session{}] on success", %{
    config: config,
    bypass: bypass
  } do
    resp = W3CTestResponses.fetch_sessions_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, sessions} = WebDriverClient.fetch_sessions(config)
    assert Enum.all?(sessions, &match?(%Session{config: ^config}, &1))
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_sessions/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        %Session{config: config} =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_sessions(config),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "end_session/1 with jwp session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.end_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.end_session(session)
  end

  @tag protocol: :w3c
  test "end_session/1 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.end_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.end_session(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "end_session/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.end_session(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "navigate_to/2 with jwp session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.navigate_to_response() |> pick()
    browser_url = "http://foo.bar.example"

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.navigate_to(session, browser_url)
  end

  @tag protocol: :w3c
  test "navigate_to/2 with w3c session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.navigate_to_response() |> pick()
    browser_url = "http://foo.bar.example"

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.navigate_to(session, browser_url)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "navigate_to/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.navigate_to(session, "http://foo.com"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "fetch_current_url/1 with w3c session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_current_url_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, url} = WebDriverClient.fetch_current_url(session)
    assert is_binary(url)
  end

  @tag protocol: :jwp
  test "fetch_current_url/1 with JWP session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_current_url_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, url} = WebDriverClient.fetch_current_url(session)
    assert is_binary(url)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_current_url/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_current_url(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "fetch_title/1 with w3c session returns {:ok, title} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_title_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, title} = WebDriverClient.fetch_title(session)
    assert is_binary(title)
  end

  @tag protocol: :jwp
  test "fetch_title/1 with JWP session returns {:ok, title} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_title_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, title} = WebDriverClient.fetch_title(session)
    assert is_binary(title)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_title/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_title(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "fetch_page_source/1 with w3c session returns {:ok, page_source} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_page_source_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, page_source} = WebDriverClient.fetch_page_source(session)
    assert is_binary(page_source)
  end

  @tag protocol: :jwp
  test "fetch_page_source/1 with JWP session returns {:ok, page_source} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_page_source_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, page_source} = WebDriverClient.fetch_page_source(session)
    assert is_binary(page_source)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_page_source/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_page_source(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_window_size/1 with JWP session returns {:ok, %Size{}} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_window_size_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, %Size{}} = WebDriverClient.fetch_window_size(session)
  end

  @tag protocol: :jwp
  test "fetch_window_size/1 with JWP session returns {:error, %ProtocolMismatchError{}} on W3C response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_window_rect_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:error,
            %ProtocolMismatchError{
              response: {:ok, %Size{}},
              expected_protocol: :jwp,
              actual_protocol: :w3c
            }} = WebDriverClient.fetch_window_size(session)
  end

  @tag protocol: :w3c
  test "fetch_window_size/1 with w3c session returns {:ok, %Size{}} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_window_rect_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Size{}} = WebDriverClient.fetch_window_size(session)
  end

  @tag protocol: :w3c
  test "fetch_window_size/1 with w3c session returns {:error, %ProtocolMismatchError{}} on jwp response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_window_size_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:error,
            %ProtocolMismatchError{
              response: {:ok, %Size{}},
              expected_protocol: :w3c,
              actual_protocol: :jwp
            }} = WebDriverClient.fetch_window_size(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_window_size/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_window_size(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "set_window_size/2 with JWP session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.set_window_size_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.set_window_size(session)
  end

  @tag protocol: :jwp
  test "set_window_size/2 with JWP session returns {:error, %ProtocolMismatchError{}} on valid W3C response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.set_window_rect_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:error,
            %ProtocolMismatchError{response: :ok, expected_protocol: :jwp, actual_protocol: :w3c}} =
             WebDriverClient.set_window_size(session)
  end

  @tag protocol: :w3c
  test "set_window_size/2 with w3c session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.set_window_rect_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.set_window_size(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "set_window_size/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.set_window_size(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_log_types/1 with JWP session returns {:ok, types} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_log_types_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_types} = WebDriverClient.fetch_log_types(session)
    assert Enum.all?(log_types, &is_binary/1)
  end

  @tag protocol: :w3c
  test "fetch_log_types/1 with w3c session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_log_types_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_types} = WebDriverClient.fetch_log_types(session)
    assert Enum.all?(log_types, &is_binary/1)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_log_types/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_log_types(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_logs/2 with JWP session returns {:ok, log_entries} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_logs_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_entries} = WebDriverClient.fetch_logs(session, "log_type")
    assert Enum.all?(log_entries, &match?(%LogEntry{}, &1))
  end

  @tag protocol: :w3c
  test "fetch_logs/2 with w3c session returns {:ok, [LogEntry.t()]} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_logs_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_entries} = WebDriverClient.fetch_logs(session, "log_type")
    assert Enum.all?(log_entries, &match?(%LogEntry{}, &1))
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_logs/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_logs(session, "log_type"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "find_element/3 with JWP session returns {:ok, element} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.find_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, %Element{}} = WebDriverClient.find_element(session, strategy, "foo")
    end)
  end

  @tag protocol: :w3c
  test "find_element/3 with W3C session returns {:ok, element} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.find_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, %Element{}} = WebDriverClient.find_element(session, strategy, "foo")
    end)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "find_element/3 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.find_element(session, :css_selector, "foo"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "find_elements/3 with JWP session returns {:ok, elements} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} = WebDriverClient.find_elements(session, strategy, "foo")
      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  @tag protocol: :jwp
  test "find_elements/3 with JWP session returns {:error, %ProtocolMismatchError{}} on valid W3C response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.find_elements_response(length: 1) |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:error,
              %ProtocolMismatchError{
                response: {:ok, elements},
                expected_protocol: :jwp,
                actual_protocol: :w3c
              }} = WebDriverClient.find_elements(session, strategy, "foo")

      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  @tag protocol: :w3c
  test "find_elements/3 with W3C session returns {:ok, elements} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} = WebDriverClient.find_elements(session, strategy, "foo")
      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  @tag protocol: :w3c
  test "find_elements/3 with W3C session returns {:error, %ProtocolMismatchError{}} on valid JWP response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.find_elements_response(length: 1) |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:error,
              %ProtocolMismatchError{
                response: {:ok, elements},
                expected_protocol: :w3c,
                actual_protocol: :jwp
              }} = WebDriverClient.find_elements(session, strategy, "foo")

      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "find_elements/3 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.find_elements(session, :css_selector, "foo"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "find_elements_from_element/4 with JWP session returns {:ok, elements} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} =
               WebDriverClient.find_elements_from_element(session, element, strategy, "foo")

      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  @tag protocol: :w3c
  test "find_elements_from_element/4 with W3C session returns {:ok, elements} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} =
               WebDriverClient.find_elements_from_element(session, element, strategy, "foo")

      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "find_elements_from_element/4 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.find_elements_from_element(session, element, :css_selector, "foo"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_active_element/1 with JWP session returns {:ok, element} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_active_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Element{}} = WebDriverClient.fetch_active_element(session)
  end

  @tag protocol: :w3c
  test "fetch_active_element/1 with W3C session returns {:ok, element} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_active_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Element{}} = WebDriverClient.fetch_active_element(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_active_element/3 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_active_element(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_element_displayed/2 with JWP session returns {:ok, displayed?} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.fetch_element_displayed_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, displayed?} = WebDriverClient.fetch_element_displayed(session, element)
    assert is_boolean(displayed?)
  end

  @tag protocol: :w3c
  test "fetch_element_displayed/2 with W3C session returns {:ok, displayed?} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.fetch_element_displayed_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, displayed?} = WebDriverClient.fetch_element_displayed(session, element)
    assert is_boolean(displayed?)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_element_displayed/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_element_displayed(session, element),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_element_attribute/3 with JWP session returns {:ok, value} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    attribute = TestData.attribute_name() |> pick()
    resp = JWPTestResponses.fetch_element_attribute_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, value} = WebDriverClient.fetch_element_attribute(session, element, attribute)
    assert is_binary(value)
  end

  @tag protocol: :w3c
  test "fetch_element_attribute/3 with W3C session returns {:ok, value} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    attribute = TestData.attribute_name() |> pick()
    resp = W3CTestResponses.fetch_element_attribute_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, value} = WebDriverClient.fetch_element_attribute(session, element, attribute)
    assert is_binary(value)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_element_attribute/3 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()
        attribute = TestData.attribute_name() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_element_attribute(session, element, attribute),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_element_property/3 with JWP session returns {:error, %WebDriverError{reason: :unsupported_operation}}",
       %{config: config} do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    property = TestData.property_name() |> pick()

    assert {:error, %WebDriverError{reason: :unsupported_operation}} =
             WebDriverClient.fetch_element_property(session, element, property)
  end

  @tag protocol: :w3c
  test "fetch_element_property/3 with W3C session returns {:ok, value} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    property = TestData.property_name() |> pick()
    resp = W3CTestResponses.fetch_element_property_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, value} = WebDriverClient.fetch_element_property(session, element, property)
    assert is_binary(value)
  end

  @tag protocol: :w3c
  test "fetch_element_property/3 with w3c session returns appropriate errors on various server responses",
       %{config: config, bypass: bypass, protocol: protocol} do
    scenario_server = set_up_error_scenario_tests(protocol, bypass)

    for error_scenario <-
          basic_error_scenarios(protocol) -- [:protocol_mismatch_error_web_driver_error] do
      session =
        build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

      element = TestData.element() |> pick()
      property = TestData.property_name() |> pick()

      assert_expected_response(
        protocol,
        WebDriverClient.fetch_element_property(session, element, property),
        error_scenario
      )
    end
  end

  @tag protocol: :jwp
  test "fetch_element_text/2 with JWP session returns {:ok, value} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.fetch_element_text_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, value} = WebDriverClient.fetch_element_text(session, element)
    assert is_binary(value)
  end

  @tag protocol: :w3c
  test "fetch_element_text/2 with W3C session returns {:ok, value} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.fetch_element_text_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, value} = WebDriverClient.fetch_element_text(session, element)
    assert is_binary(value)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_element_text/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) -- [:protocl_m] do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_element_text(session, element),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "click_element/2 with JWP session returns :ok on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.click_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.click_element(session, element)
  end

  @tag protocol: :w3c
  test "click_element/2 with W3C session returns :ok on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.click_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.click_element(session, element)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "click_element/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.click_element(session, element),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "clear_element/2 with JWP session returns :ok on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.clear_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.clear_element(session, element)
  end

  @tag protocol: :w3c
  test "clear_element/2 with W3C session returns :ok on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.clear_element_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.clear_element(session, element)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "clear_element/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.clear_element(session, element),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "send_keys_to_element/3 with jwp session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.send_keys_to_element_response() |> pick()
    keys = ["foo", :tab]

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.send_keys_to_element(session, element, keys)
  end

  @tag protocol: :w3c
  test "send_keys_to_element/3 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.send_keys_to_element_response() |> pick()
    keys = ["foo", :tab]

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.send_keys_to_element(session, element, keys)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "send_keys_to_element/3 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        element = TestData.element() |> pick()

        assert_expected_response(
          protocol,
          WebDriverClient.send_keys_to_element(session, element, "foo"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "send_keys/2 with jwp session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.send_keys_response() |> pick()
    keys = ["foo", :tab]

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.send_keys(session, keys)
  end

  @tag protocol: :jwp
  test "send_keys/2 with jwp session returns appropriate errors on various server responses",
       %{config: config, bypass: bypass, protocol: protocol} do
    scenario_server = set_up_error_scenario_tests(protocol, bypass)

    for error_scenario <-
          basic_error_scenarios(protocol) -- [:protocol_mismatch_error_web_driver_error] do
      session =
        build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

      keys = ["foo", :tab]

      assert_expected_response(
        protocol,
        WebDriverClient.send_keys(session, keys),
        error_scenario
      )
    end
  end

  @tag protocol: :w3c
  test "send_keys/2 with w3c session returns {:error, %WebDriverError{reason: :unsupported_operation}}",
       %{config: config} do
    session = TestData.session(config: constant(config)) |> pick()
    keys = ["foo", :tab]

    assert {:error, %WebDriverError{reason: :unsupported_operation}} =
             WebDriverClient.send_keys(session, keys)
  end

  @tag protocol: :w3c
  test "fetch_alert_text/1 with w3c session returns {:ok, alert_text} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_alert_text_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, alert_text} = WebDriverClient.fetch_alert_text(session)
    assert is_binary(alert_text)
  end

  @tag protocol: :jwp
  test "fetch_alert_text/1 with JWP session returns {:ok, alert_text} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_alert_text_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, alert_text} = WebDriverClient.fetch_alert_text(session)
    assert is_binary(alert_text)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_alert_text/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_alert_text(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "accept_alert/1 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.accept_alert_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.accept_alert(session)
  end

  @tag protocol: :jwp
  test "accept_alert/1 with JWP session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.accept_alert_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.accept_alert(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "accept_alert/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.accept_alert(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "dismiss_alert/1 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.dismiss_alert_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.dismiss_alert(session)
  end

  @tag protocol: :jwp
  test "dismiss_alert/1 with JWP session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.dismiss_alert_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.dismiss_alert(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "dismiss_alert/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.dismiss_alert(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "send_alert_text/2 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.send_alert_text_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.send_alert_text(session, "foo")
  end

  @tag protocol: :jwp
  test "send_alert_text/2 with JWP session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.send_alert_text_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.send_alert_text(session, "foo")
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "send_alert_text/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        keys = "foo"

        assert_expected_response(
          protocol,
          WebDriverClient.send_alert_text(session, keys),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "take_screenshot/1 with w3c session returns {:ok, image_data} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.take_screenshot_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, image_data} = WebDriverClient.take_screenshot(session)
    assert is_binary(image_data)
  end

  @tag protocol: :jwp
  test "take_screenshot/1 with JWP session returns {:ok, image_data} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.take_screenshot_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, image_data} = WebDriverClient.take_screenshot(session)
    assert is_binary(image_data)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "take_screenshot/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.take_screenshot(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_cookies/2 with JWP session returns {:ok, cookies} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_cookies_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, cookies} = WebDriverClient.fetch_cookies(session)
    assert Enum.all?(cookies, &match?(%Cookie{}, &1))
  end

  @tag protocol: :w3c
  test "fetch_cookies/2 with w3c session returns {:ok, cookies} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_cookies_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, cookies} = WebDriverClient.fetch_cookies(session)
    assert Enum.all?(cookies, &match?(%Cookie{}, &1))
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_cookies/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_cookies(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "set_cookie/3 with JWP session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.set_cookie_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.set_cookie(session, "greeting", "hello world")
  end

  @tag protocol: :w3c
  test "set_cookie/3 with w3c session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.set_cookie_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.set_cookie(session, "greeting", "hello world")
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "set_cookie/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.set_cookie(session, "foo", "bar"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "delete_cookies/1 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.delete_cookies_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.delete_cookies(session)
  end

  @tag protocol: :jwp
  test "delete_cookies/1 with JWP session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.delete_cookies_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.delete_cookies(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "delete_cookies/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        session =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.delete_cookies(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "fetch_server_status/1 with w3c session returns {:ok, ServerStatus} on success", %{
    config: config,
    bypass: bypass
  } do
    resp = W3CTestResponses.fetch_server_status_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, %ServerStatus{ready?: ready?}} = WebDriverClient.fetch_server_status(config)
    assert is_boolean(ready?)
  end

  @tag protocol: :jwp
  test "fetch_server_status/1 with JWP session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    resp = JWPTestResponses.fetch_server_status_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, %ServerStatus{ready?: ready?}} = WebDriverClient.fetch_server_status(config)
    assert is_boolean(ready?)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_server_status/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass, protocol: protocol} do
      scenario_server = set_up_error_scenario_tests(protocol, bypass)

      for error_scenario <- basic_error_scenarios(protocol) do
        %Session{config: config} =
          build_session_for_scenario(protocol, scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          protocol,
          WebDriverClient.fetch_server_status(config),
          error_scenario
        )
      end
    end
  end

  defp set_up_error_scenario_tests(:jwp, bypass) do
    JWPErrorScenarios.set_up_error_scenario_tests(bypass)
  end

  defp set_up_error_scenario_tests(:w3c, bypass) do
    W3CErrorScenarios.set_up_error_scenario_tests(bypass)
  end

  defp basic_error_scenarios(:w3c) do
    [
      :http_client_error,
      :unexpected_response_format,
      :web_driver_error,
      :protocol_mismatch_error_web_driver_error
    ]
  end

  defp basic_error_scenarios(:jwp) do
    [
      :http_client_error,
      :unexpected_response_format,
      :web_driver_error,
      :protocol_mismatch_error_web_driver_error
    ]
  end

  defp build_session_for_scenario(:jwp, scenario_server, bypass, config, error_scenario) do
    scenario = JWPErrorScenarios.get_named_scenario(error_scenario)

    JWPErrorScenarios.build_session_for_scenario(scenario_server, bypass, config, scenario)
  end

  defp build_session_for_scenario(:w3c, scenario_server, bypass, config, error_scenario) do
    scenario = W3CErrorScenarios.get_named_scenario(error_scenario)

    W3CErrorScenarios.build_session_for_scenario(scenario_server, bypass, config, scenario)
  end

  defp assert_expected_response(protocol, response, :http_client_error)
       when protocol in [:w3c, :jwp] do
    assert {:error, %ConnectionError{}} = response
  end

  defp assert_expected_response(protocol, response, :protocol_mismatch_error_web_driver_error)
       when protocol in [:w3c, :jwp] do
    assert {:error,
            %ProtocolMismatchError{
              response: {:error, %WebDriverError{}},
              expected_protocol: ^protocol
            }} = response
  end

  defp assert_expected_response(protocol, response, :unexpected_response_format)
       when protocol in [:w3c, :jwp] do
    assert {:error, %UnexpectedResponseError{protocol: ^protocol}} = response
  end

  defp assert_expected_response(protocol, response, :web_driver_error)
       when protocol in [:w3c, :jwp] do
    assert {:error, %WebDriverError{}} = response
  end

  defp build_start_session_payload do
    %{"capablities" => %{"browserName" => "firefox"}}
  end

  defp stub_bypass_response(bypass, response) do
    Bypass.stub(bypass, :any, :any, fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
    end)
  end
end
