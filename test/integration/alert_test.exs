defmodule WebDriverClient.Integration.AlertTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.InteractionsPage
  alias WebDriverClient.Session
  alias WebDriverClient.WebDriverError

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  scenarios =
    Scenarios.all()
    |> Enum.reject(&match?(%Scenario{driver: :phantomjs}, &1))

  TestGenerator.generate_describe_per_scenario scenarios: scenarios do
    test "interacting with alerts", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, InteractionsPage.url())

      {:error, %WebDriverError{reason: :no_such_alert}} =
        WebDriverClient.fetch_alert_text(session)

      {:ok, open_alert_button} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          InteractionsPage.css_selector_for_open_alert_button()
        )

      :ok = WebDriverClient.click_element(session, open_alert_button)

      {:ok, alert_text} = WebDriverClient.fetch_alert_text(session)
      assert InteractionsPage.alert_text() == alert_text
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
