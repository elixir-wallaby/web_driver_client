defmodule WebDriverClient.Integration.ElementAttributesTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.ElementsPage
  alias WebDriverClient.Session

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  TestGenerator.generate_describe_per_scenario do
    test "returning visibility", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:ok, [element]} =
               WebDriverClient.find_elements(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_singular_element()
               )

      assert {:ok, true} = WebDriverClient.fetch_element_displayed(session, element)

      assert {:ok, [element]} =
               WebDriverClient.find_elements(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_non_visible_element()
               )

      assert {:ok, false} = WebDriverClient.fetch_element_displayed(session, element)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
