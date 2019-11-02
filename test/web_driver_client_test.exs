defmodule WebDriverClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn

  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.Session
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError

  @moduletag :bypass
  @moduletag :capture_log

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
      test_id = generate_test_id()
      config = prepend_test_id_to_base_url(config, test_id)

      Bypass.expect_once(bypass, "GET", "/#{test_id}/sessions", fn conn ->
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

  test "fetch_current_url/1 with valid data calls the correct url and returns the response", %{
    config: config,
    bypass: bypass
  } do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    browser_url = "http://foo.bar.example"

    Bypass.expect_once(bypass, "GET", "/session/#{session_id}/url", fn conn ->
      response_body =
        %{"sessionId" => "foo", "status" => 1, "value" => browser_url}
        |> Jason.encode!()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response_body)
    end)

    assert {:ok, ^browser_url} = WebDriverClient.fetch_current_url(session)
  end

  test "fetch_current_url/1 with unexpected data returns error", %{config: config, bypass: bypass} do
    %Session{id: session_id} = session = TestData.session(config: constant(config)) |> pick()

    Bypass.expect_once(bypass, "GET", "/session/#{session_id}/url", fn conn ->
      response_body = Jason.encode!(%{})

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response_body)
    end)

    assert {:error, %UnexpectedResponseFormatError{}} = WebDriverClient.fetch_current_url(session)
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

  @typep test_id :: String.t()

  @spec prepend_test_id_to_base_url(Config.t(), test_id) :: String.t()
  defp prepend_test_id_to_base_url(%Config{base_url: base_url} = config, test_id)
       when is_binary(test_id) do
    base_url = Path.join(base_url, test_id)
    %Config{config | base_url: base_url}
  end

  @spec generate_test_id :: test_id
  defp generate_test_id do
    string(:alphanumeric, length: 40)
    |> Enum.take(1)
    |> List.first()
  end
end
