defmodule WebDriverClient.Integration.FindingElementsTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.Element
  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.ElementsPage
  alias WebDriverClient.Session

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  TestGenerator.generate_describe_per_scenario do
    test "finding elements", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:ok, [%Element{}]} =
               WebDriverClient.find_elements(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_singular_element()
               )

      assert {:ok, []} =
               WebDriverClient.find_elements(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_non_existent_element()
               )
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
