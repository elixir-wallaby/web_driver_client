defmodule WebDriverClient.Integration.ElementInteractionTest do
  use ExUnit.Case, async: false

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

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:ok, text_input_element} =
               WebDriverClient.find_element(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_prefilled_text_input()
               )

      assert {:ok, value} =
               WebDriverClient.fetch_element_attribute(session, text_input_element, "value")

      assert is_binary(value) && value != ""

      assert :ok = WebDriverClient.clear_element(session, text_input_element)

      assert {:ok, ""} =
               WebDriverClient.fetch_element_attribute(session, text_input_element, "value")
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
