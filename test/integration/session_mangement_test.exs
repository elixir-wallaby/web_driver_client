defmodule WebDriverClient.Integration.SessionManagementTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.Session

  require WebDriverClient.IntegrationTesting.TestGenerator

  @moduletag :capture_log
  @moduletag :integration

  TestGenerator.generate_describe_per_scenario do
    setup :close_existing_sessions

    test "starting, listing, and ending a session", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)

      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, %Session{} = session} =
        WebDriverClient.start_session(
          payload,
          config: config
        )

      assert {:ok, [^session]} = WebDriverClient.fetch_sessions(config: config)

      assert :ok = WebDriverClient.end_session(session)

      if match?(%Scenario{driver: :chromedriver}, scenario) do
        # Sleep here to prevent chromedriver segmentation fault
        Process.sleep(100)
      end

      assert {:ok, []} = WebDriverClient.fetch_sessions(config: config)
    end
  end

  defp close_existing_sessions(%{scenario: scenario}) do
    config = Scenarios.get_config(scenario)

    {:ok, sessions} = WebDriverClient.fetch_sessions(config: config)

    Enum.each(sessions, fn session ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
