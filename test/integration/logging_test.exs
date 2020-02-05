defmodule WebDriverClient.Integration.LoggingTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.LoggingPage
  alias WebDriverClient.LogEntry
  alias WebDriverClient.WebDriverError

  require WebDriverClient.IntegrationTesting.TestGenerator

  @moduletag :capture_log
  @moduletag :integration

  TestGenerator.generate_describe_per_scenario do
    test "retrieving logs", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      :ok = WebDriverClient.navigate_to(session, LoggingPage.url())

      case scenario do
        %Scenario{driver: :chromedriver, protocol: :w3c} ->
          # Chromedriver does not allow for fetching log types in w3c mode
          assert {:error, %WebDriverError{reason: :unknown_command}} =
                   WebDriverClient.fetch_log_types(session)

          for log_type <- ["browser", "driver"] do
            {:ok, logs} = WebDriverClient.fetch_logs(session, log_type)
            assert Enum.all?(logs, &match?(%LogEntry{}, &1))
          end

        %Scenario{} ->
          {:ok, log_types} = WebDriverClient.fetch_log_types(session)
          assert Enum.all?(log_types, &is_binary/1)

          for log_type <- log_types do
            {:ok, logs} = WebDriverClient.fetch_logs(session, log_type)
            assert Enum.all?(logs, &match?(%LogEntry{}, &1))
          end
      end
    end
  end
end
