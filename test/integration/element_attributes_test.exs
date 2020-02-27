defmodule WebDriverClient.Integration.ElementAttributesTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.ElementsPage
  alias WebDriverClient.IntegrationTesting.TestPages.MousePage
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.WebDriverError

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

    test "returning element properties", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:ok, element} =
               WebDriverClient.find_element(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_sample_list()
               )

      case scenario do
        %Scenario{protocol: :w3c} ->
          assert {:ok, "UL"} = WebDriverClient.fetch_element_property(session, element, "tagName")

        %Scenario{protocol: :jwp} ->
          assert {:error, %WebDriverError{reason: :unsupported_operation}} =
                   WebDriverClient.fetch_element_property(session, element, "tagName")
      end
    end

    test "returning element size", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, MousePage.url())

      {:ok, element} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          MousePage.css_selector_for_hoverable_element()
        )

      %MousePage.Rect{width: width, height: height} = MousePage.hoverable_element_rect()

      assert {:ok, %Size{width: ^width, height: ^height}} =
               WebDriverClient.fetch_element_size(session, element)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
