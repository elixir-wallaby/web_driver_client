defmodule WebDriverClient.Integration.InteractionTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.InteractionsPage
  alias WebDriverClient.Session

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  TestGenerator.generate_describe_per_scenario do
    test "clicking a button", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, InteractionsPage.url())

      {:ok, switchable_text_element} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          InteractionsPage.css_selector_for_switchable_text()
        )

      {:ok, original_value} = WebDriverClient.fetch_element_text(session, switchable_text_element)

      {:ok, switch_text_button} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          InteractionsPage.css_selector_for_switch_text_button()
        )

      :ok = WebDriverClient.click_element(session, switch_text_button)

      {:ok, new_value} = WebDriverClient.fetch_element_text(session, switchable_text_element)

      assert original_value != new_value

      :ok = WebDriverClient.clear_element(session, switchable_text_element)

      assert {:ok, ""} = WebDriverClient.fetch_element_text(session, switchable_text_element)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
