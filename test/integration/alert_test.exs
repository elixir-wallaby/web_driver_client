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

      {:error, %WebDriverError{reason: :no_such_alert}} = WebDriverClient.accept_alert(session)

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

      :ok = WebDriverClient.accept_alert(session)

      {:error, %WebDriverError{reason: :no_such_alert}} =
        WebDriverClient.fetch_alert_text(session)
    end

    test "interacting with confirms", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, InteractionsPage.url())

      {:error, %WebDriverError{reason: :no_such_alert}} = WebDriverClient.accept_alert(session)

      {:error, %WebDriverError{reason: :no_such_alert}} =
        WebDriverClient.fetch_alert_text(session)

      {:ok, open_confirm_button} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          InteractionsPage.css_selector_for_open_confirm_button()
        )

      {:ok, confirm_prompt_output_element} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          InteractionsPage.css_selector_for_confirm_prompt_output()
        )

      :ok = WebDriverClient.click_element(session, open_confirm_button)

      :ok = WebDriverClient.accept_alert(session)

      assert {:ok, text} =
               WebDriverClient.fetch_element_text(session, confirm_prompt_output_element)

      assert InteractionsPage.confirm_accepted_result_text() == text

      :ok = WebDriverClient.click_element(session, open_confirm_button)
      :ok = WebDriverClient.dismiss_alert(session)

      assert {:ok, text} =
               WebDriverClient.fetch_element_text(session, confirm_prompt_output_element)

      assert InteractionsPage.confirm_dismissed_result_text() == text

      :ok = WebDriverClient.click_element(session, open_confirm_button)

      {:error, %WebDriverError{reason: :unexpected_alert_open}} =
        WebDriverClient.click_element(session, open_confirm_button)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
