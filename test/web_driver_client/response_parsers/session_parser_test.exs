defmodule WebDriverClient.ResponseParsers.SessionParserTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.ResponseParsers.SessionParser
  alias WebDriverClient.Session
  alias WebDriverClient.TestData

  test "parse/1 returns {:ok, Session.t()} with older desiredCapabilities based response (from ChromeDriver)" do
    response_body = %{
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

    session_id = get_in(response_body, ["value", "sessionId"])
    [config] = TestData.config() |> Enum.take(1)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             SessionParser.parse(response_body, config)
  end

  test "parse/1 returns {:ok, Session.t()} with newer capabilities based response (from ChromeDriver)" do
    response_body = %{
      "sessionId" => "3be66d1c50597cd8bba8ba87c4795b69",
      "status" => 0,
      "value" => %{
        "acceptInsecureCerts" => false,
        "acceptSslCerts" => false,
        "applicationCacheEnabled" => false,
        "browserConnectionEnabled" => false,
        "browserName" => "chrome",
        "chrome" => %{
          "chromedriverVersion" =>
            "77.0.3865.40 (f484704e052e0b556f8030b65b953dce96503217-refs/branch-heads/3865@{#442})",
          "userDataDir" =>
            "/var/folders/my/4s0mq9sd4k16kwdgb0ywr4s00000gn/T/.com.google.Chrome.MV8iiR"
        },
        "cssSelectorsEnabled" => true,
        "databaseEnabled" => false,
        "goog:chromeOptions" => %{"debuggerAddress" => "localhost:63379"},
        "handlesAlerts" => true,
        "hasTouchScreen" => false,
        "javascriptEnabled" => true,
        "locationContextEnabled" => true,
        "mobileEmulationEnabled" => false,
        "nativeEvents" => true,
        "networkConnectionEnabled" => false,
        "pageLoadStrategy" => "normal",
        "platform" => "Mac OS X",
        "proxy" => %{},
        "rotatable" => false,
        "setWindowRect" => true,
        "strictFileInteractability" => false,
        "takesHeapSnapshot" => true,
        "takesScreenshot" => true,
        "timeouts" => %{"implicit" => 0, "pageLoad" => 300_000, "script" => 30_000},
        "unexpectedAlertBehaviour" => "ignore",
        "version" => "77.0.3865.90",
        "webStorageEnabled" => true
      }
    }

    session_id = Map.get(response_body, "sessionId")
    [config] = TestData.config() |> Enum.take(1)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             SessionParser.parse(response_body, config)
  end

  test "parse/1 returns :error on unexpected_response" do
    [config] = TestData.config() |> Enum.take(1)

    assert :error = SessionParser.parse("foo", config)
  end
end
