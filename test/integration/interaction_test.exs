defmodule WebDriverClient.Integration.InteractionTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.Config
  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.FormPage
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

      assert {:ok, ^switch_text_button} = WebDriverClient.fetch_active_element(session)

      {:ok, new_value} = WebDriverClient.fetch_element_text(session, switchable_text_element)

      assert original_value != new_value

      :ok = WebDriverClient.clear_element(session, switchable_text_element)

      assert {:ok, ""} = WebDriverClient.fetch_element_text(session, switchable_text_element)
    end

    test "filling out a form", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, FormPage.url())

      {:ok, first_name_field} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          FormPage.css_selector_for_first_name_field()
        )

      {:ok, last_name_field} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          FormPage.css_selector_for_last_name_field()
        )

      :ok = WebDriverClient.click_element(session, first_name_field)

      assert {:ok, ^first_name_field} = WebDriverClient.fetch_active_element(session)

      :ok =
        WebDriverClient.send_keys_to_element(session, first_name_field, [
          "Aaa",
          :backspace,
          "ron",
          :tab
        ])

      case config do
        %Config{protocol: :jwp} ->
          assert {:ok, "Aaron"} =
                   WebDriverClient.fetch_element_attribute(session, first_name_field, "value")

        %Config{protocol: :w3c} ->
          assert {:ok, "Aaron"} =
                   WebDriverClient.fetch_element_property(session, first_name_field, "value")
      end

      assert {:ok, ^last_name_field} = WebDriverClient.fetch_active_element(session)
    end
  end

  # Geckodriver doesn't work properly here:
  # https://bugzilla.mozilla.org/show_bug.cgi?id=1494661
  scenarios =
    Scenarios.all()
    |> Enum.reject(&match?(%Scenario{browser: :firefox, protocol: :w3c}, &1))

  TestGenerator.generate_describe_per_scenario scenarios: scenarios do
    test "send_keys uses nil to reset modifier keys", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, FormPage.url())

      {:ok, last_name_field} =
        WebDriverClient.find_element(
          session,
          :css_selector,
          FormPage.css_selector_for_last_name_field()
        )

      :ok =
        WebDriverClient.send_keys_to_element(session, last_name_field, [
          :shift,
          "r",
          :null,
          "enner"
        ])

      case config do
        %Config{protocol: :jwp} ->
          assert {:ok, "Renner"} =
                   WebDriverClient.fetch_element_attribute(session, last_name_field, "value")

        %Config{protocol: :w3c} ->
          assert {:ok, "Renner"} =
                   WebDriverClient.fetch_element_property(session, last_name_field, "value")
      end
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
