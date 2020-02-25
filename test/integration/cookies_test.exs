defmodule WebDriverClient.Integration.CookiesTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.Cookie
  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.ElementsPage
  alias WebDriverClient.Session

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  TestGenerator.generate_describe_per_scenario do
    test "fetching and setting cookies", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert :ok = WebDriverClient.delete_cookies(session)

      assert {:ok, []} = WebDriverClient.fetch_cookies(session)

      %URI{host: host} = ElementsPage.url() |> URI.parse()

      case scenario do
        %Scenario{driver: :phantomjs} ->
          # PhantomJS 2.1.1 returns an error (1.9.8 does not), but it works anyways
          WebDriverClient.set_cookie(session, "mycookie", "myvalue")

        %Scenario{} ->
          assert :ok = WebDriverClient.set_cookie(session, "mycookie", "myvalue")
      end

      assert {:ok,
              [
                %Cookie{
                  name: "mycookie",
                  value: "myvalue",
                  domain: ^host
                }
              ]} = WebDriverClient.fetch_cookies(session)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
