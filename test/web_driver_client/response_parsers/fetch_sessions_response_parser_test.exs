defmodule WebDriverClient.ResponseParsers.FetchSessionsResponseParserTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.ResponseParsers.FetchSessionsResponseParser
  alias WebDriverClient.Session
  alias WebDriverClient.TestData

  test "parse/2 returns {:ok, [Session.t()]} on expected response" do
    response_body = %{
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

    session_id =
      response_body
      |> Map.fetch!("value")
      |> List.first()
      |> Map.fetch!("id")

    [config] = TestData.config() |> Enum.take(1)

    assert {:ok, [%Session{id: ^session_id, config: ^config}]} =
             FetchSessionsResponseParser.parse(response_body, config)
  end

  test "parse/2 returns :error on unexpected_response" do
    [config] = TestData.config() |> Enum.take(1)

    assert :error = FetchSessionsResponseParser.parse("foo", config)
  end

  test "parse/2 returns :error when one of the values is invalid" do
    response_body = %{
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
        },
        %{"invalid" => "data"}
      ]
    }

    [config] = TestData.config() |> Enum.take(1)

    assert :error = FetchSessionsResponseParser.parse(response_body, config)
  end
end
