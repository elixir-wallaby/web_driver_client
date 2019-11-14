defmodule WebDriverClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn
  import WebDriverClient.ErrorScenarios

  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.JSONWireProtocolClient.TestResponses, as: JWPTestResponses
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError
  alias WebDriverClient.W3CWireProtocolClient.TestResponses, as: W3CTestResponses

  @moduletag :bypass
  @moduletag :capture_log

  @protocols [:jwp, :w3c]

  test "start_session/1 returns {:ok, Session.t()} with a valid response", %{
    config: config,
    bypass: bypass
  } do
    response_body = build_session_response()
    session_id = get_in(response_body, ["value", "sessionId"])
    payload = build_start_session_payload()

    Bypass.expect_once(bypass, "POST", "/session", fn conn ->
      conn = parse_params(conn)
      assert ^payload = conn.params

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(response_body))
    end)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             WebDriverClient.start_session(payload, config: config)
  end

  test "start_session/1 returns {:error, UnexpectedResponseFormatError.t()} with an unexpected response",
       %{
         config: config,
         bypass: bypass
       } do
    response_body = "foo"
    payload = build_start_session_payload()

    Bypass.expect_once(bypass, "POST", "/session", fn conn ->
      conn
      |> send_resp(200, response_body)
    end)

    assert {:error, %UnexpectedResponseFormatError{response_body: ^response_body}} =
             WebDriverClient.start_session(payload, config: config)
  end

  test "fetch_sessions/1 returns {:ok, [%Session{}]} on a valid response", %{
    bypass: bypass,
    config: config
  } do
    response_body = build_fetch_sessions_response()

    session_id =
      response_body
      |> Map.fetch!("value")
      |> List.first()
      |> Map.fetch!("id")

    Bypass.expect_once(bypass, "GET", "/sessions", fn conn ->
      json = Jason.encode!(response_body)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, json)
    end)

    assert {:ok, [%Session{id: ^session_id, config: ^config} | _]} =
             WebDriverClient.fetch_sessions(config: config)
  end

  test "fetch_sessions/1 returns {:error, %UnexpectedResponseFormatError{}} with an unexpected response",
       %{bypass: bypass, config: config} do
    response_body = "{}"

    Bypass.expect_once(bypass, "GET", "/sessions", fn conn ->
      send_resp(conn, 200, response_body)
    end)

    assert {:error, %UnexpectedResponseFormatError{response_body: ^response_body}} =
             WebDriverClient.fetch_sessions(config: config)
  end

  property "fetch_sessions/1 returns {:error, %UnexpectedResponseFormatError{}} with invalid json",
           %{bypass: bypass, config: config} do
    check all response_body <-
                one_of([
                  string(:alphanumeric),
                  constant("{}")
                ]),
              content_type <-
                one_of([
                  json_content_type(),
                  string(:alphanumeric)
                ]) do
      {config, prefix} = prefix_base_url_for_multiple_runs(config)

      Bypass.expect_once(bypass, "GET", "/#{prefix}/sessions", fn conn ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, response_body)
      end)

      assert {:error, %UnexpectedResponseFormatError{}} =
               WebDriverClient.fetch_sessions(config: config)
    end
  end

  test "fetch_sessions/1 returns {:error, %UnexpectedStatusCodeError{}} with a non-200 status code",
       %{bypass: bypass, config: config} do
    Bypass.expect_once(bypass, "GET", "/sessions", fn conn ->
      send_resp(conn, 400, "{}")
    end)

    assert {:error, %UnexpectedStatusCodeError{}} = WebDriverClient.fetch_sessions(config: config)
  end

  test "fetch_sessions/1 returns {:error, %HTTPClientError{}} when unable to connect", %{
    bypass: bypass,
    config: config
  } do
    Bypass.down(bypass)

    assert {:error, %HTTPClientError{reason: :econnrefused}} =
             WebDriverClient.fetch_sessions(config: config)
  end

  test "fetch_sessions/1 returns {:error, %HTTPClientError{}} for unknown domain" do
    config = Config.build(base_url: "http://doesnotexist.aaronrenner.io")

    assert {:error, %HTTPClientError{reason: :nxdomain}} =
             WebDriverClient.fetch_sessions(config: config)
  end

  test "end_session/1 with a %Session{} uses the config on the session", %{
    bypass: bypass,
    config: config
  } do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    Bypass.expect_once(bypass, "DELETE", "/session/#{session_id}", fn conn ->
      send_resp(conn, 200, "")
    end)

    assert :ok = WebDriverClient.end_session(session)
  end

  test "navigate_to/1 with valid data calls the correct url and returns the response", %{
    config: config,
    bypass: bypass
  } do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    browser_url = "http://foo.bar.example"

    Bypass.expect_once(bypass, "POST", "/session/#{session_id}/url", fn conn ->
      conn = parse_params(conn)

      assert conn.params == %{"url" => browser_url}

      response_body = Jason.encode!(%{"value" => nil})

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response_body)
    end)

    assert :ok = WebDriverClient.navigate_to(session, browser_url)
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
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_current_url(session),
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

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_window_size/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
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
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
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
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_log_types(session),
          error_scenario
        )
      end
    end
  end

  defp build_session_response do
    %{
      "value" => %{
        "capabilities" => %{
          "acceptInsecureCerts" => false,
          "browserName" => "chrome",
          "browserVersion" => "77.0.3865.120",
          "chrome" => %{
            "chromedriverVersion" =>
              "77.0.3865.40 (f484704e052e0b556f8030b65b953dce96503217-refs/branch-heads/3865@{#442})",
            "userDataDir" =>
              "/var/folders/mn/dxbldtrx3jv0q_hnnz8kfmf00000gn/T/.com.google.Chrome.QNPU8L"
          },
          "goog:chromeOptions" => %{"debuggerAddress" => "localhost:62775"},
          "networkConnectionEnabled" => false,
          "pageLoadStrategy" => "normal",
          "platformName" => "mac os x",
          "proxy" => %{},
          "setWindowRect" => true,
          "strictFileInteractability" => false,
          "timeouts" => %{"implicit" => 0, "pageLoad" => 300_000, "script" => 30_000},
          "unhandledPromptBehavior" => "dismiss and notify"
        },
        "sessionId" => "882326fd74ae485962d435e265c51fbd"
      }
    }
  end

  defp build_fetch_sessions_response do
    %{
      "sessionId" => "",
      "status" => 0,
      "value" => [
        %{
          "capabilities" => %{
            "acceptInsecureCerts" => false,
            "browserName" => "chrome",
            "browserVersion" => "77.0.3865.120",
            "chrome" => %{
              "chromedriverVersion" =>
                "77.0.3865.40 (f484704e052e0b556f8030b65b953dce96503217-refs/branch-heads/3865@{#442})",
              "userDataDir" =>
                "/var/folders/mn/dxbldtrx3jv0q_hnnz8kfmf00000gn/T/.com.google.Chrome.Iw15gJ"
            },
            "goog:chromeOptions" => %{
              "debuggerAddress" => "localhost:63322"
            },
            "networkConnectionEnabled" => false,
            "pageLoadStrategy" => "normal",
            "platformName" => "mac os x",
            "proxy" => %{},
            "setWindowRect" => true,
            "strictFileInteractability" => false,
            "timeouts" => %{
              "implicit" => 0,
              "pageLoad" => 300_000,
              "script" => 30_000
            },
            "unhandledPromptBehavior" => "dismiss and notify"
          },
          "id" => "9e8adbbf4187003d9e0d9b2934a9c5d0"
        }
      ]
    }
  end

  defp build_start_session_payload do
    %{"capablities" => %{"browserName" => "firefox"}}
  end

  @spec json_content_type :: StreamData.t(String.t())
  defp json_content_type do
    constant("application/json")
  end

  defp stub_bypass_response(bypass, response) do
    Bypass.stub(bypass, :any, :any, fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
    end)
  end
end
