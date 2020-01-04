defmodule WebDriverClient.Integration.FindingElementsTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.Element
  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.ElementsPage
  alias WebDriverClient.Session
  alias WebDriverClient.WebDriverError

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

      assert {:ok, [%Element{}, %Element{}, %Element{}, %Element{}]} =
               WebDriverClient.find_elements(
                 session,
                 :xpath,
                 ElementsPage.xpath_selector_for_list_items()
               )

      {:ok, [list_element]} =
        WebDriverClient.find_elements(
          session,
          :css_selector,
          ElementsPage.css_selector_for_sample_list()
        )

      assert {:ok, [%Element{}, %Element{}, %Element{}, %Element{}]} =
               WebDriverClient.find_elements_from_element(
                 session,
                 list_element,
                 :css_selector,
                 "li"
               )
    end

    test "invalid selectors", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:error, %WebDriverError{reason: reason}} =
               WebDriverClient.find_elements(
                 session,
                 :css_selector,
                 "checkbox:foo"
               )

      # For some reason PhantomJS returns :invalid_element_state
      assert reason in [:invalid_selector, :invalid_element_state]
    end

    test "finding a singular element", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, ElementsPage.url())

      assert {:ok, %Element{}} =
               WebDriverClient.find_element(
                 session,
                 :css_selector,
                 ElementsPage.css_selector_for_singular_element()
               )
    end

    test "finding a singular element that doesn't exist", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      assert {:error, %WebDriverError{reason: :no_such_element}} =
               WebDriverClient.find_element(session, :css_selector, "#does-not-exist")
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
