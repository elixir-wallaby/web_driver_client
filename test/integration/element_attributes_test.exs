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

      {:ok, session} = WebDriverClient.start_session(config, payload)

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

    test "returning visible text", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:ok, element} =
               WebDriverClient.find_element(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_page_heading_element()
               )

      assert {:ok, "Welcome to the Elements Page!"} =
               WebDriverClient.fetch_element_text(session, element)

      assert {:ok, hidden_element} =
               WebDriverClient.find_element(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_non_visible_element()
               )

      assert {:ok, ""} = WebDriverClient.fetch_element_text(session, hidden_element)
    end

    test "returning element attributes", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())
      text_input_id = ElementsPage.text_input_id()

      assert {:ok, text_input_element} =
               WebDriverClient.find_element(
                 session,
                 :css_selector,
                 "#" <> text_input_id
               )

      assert {:ok, ^text_input_id} =
               WebDriverClient.fetch_element_attribute(session, text_input_element, "id")

      assert {:ok, nil} =
               WebDriverClient.fetch_element_attribute(
                 session,
                 text_input_element,
                 "unknown-attribute"
               )

      assert {:ok, nil} =
               WebDriverClient.fetch_element_attribute(
                 session,
                 text_input_element,
                 "invalid attribute name"
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
