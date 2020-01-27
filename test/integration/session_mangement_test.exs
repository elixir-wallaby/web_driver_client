defmodule WebDriverClient.Integration.SessionManagementTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.ProtocolMismatchError
  alias WebDriverClient.Session
  alias WebDriverClient.WebDriverError

  require WebDriverClient.IntegrationTesting.TestGenerator

  @moduletag :capture_log
  @moduletag :integration

  TestGenerator.generate_describe_per_scenario do
    setup :close_existing_sessions

    test "starting, listing, and ending a session", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)

      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, %Session{} = session} = WebDriverClient.start_session(config, payload)

      assert {:ok, [^session]} = WebDriverClient.fetch_sessions(config)

      assert :ok = WebDriverClient.end_session(session)

      if match?(%Scenario{driver: :chromedriver}, scenario) do
        # Sleep here to prevent chromedriver segmentation fault
        Process.sleep(100)
      end

      assert {:ok, []} = WebDriverClient.fetch_sessions(config)

      # Ending an already ended session
      case scenario do
        %Scenario{driver: :selenium_2} ->
          assert {:error, %WebDriverError{reason: :unknown_error}} =
                   WebDriverClient.end_session(session)

        %Scenario{driver: :chromedriver, protocol: :w3c} ->
          assert :ok = WebDriverClient.end_session(session)

        %Scenario{driver: :chromedriver, protocol: :jwp} ->
          assert {:error,
                  %ProtocolMismatchError{
                    response: :ok,
                    expected_protocol: :jwp,
                    actual_protocol: :w3c
                  }} = WebDriverClient.end_session(session)

        %Scenario{protocol: :jwp} ->
          assert {:error, %WebDriverError{reason: :unknown_command}} =
                   WebDriverClient.end_session(session)

        %Scenario{protocol: :w3c} ->
          assert {:error, %WebDriverError{reason: :invalid_session_id}} =
                   WebDriverClient.end_session(session)
      end
    end
  end

  defp close_existing_sessions(%{scenario: scenario}) do
    config = Scenarios.get_config(scenario)

    {:ok, sessions} = WebDriverClient.fetch_sessions(config)

    Enum.each(sessions, fn session ->
      case WebDriverClient.end_session(session) do
        :ok -> :ok
        {:error, %ProtocolMismatchError{response: :ok}} -> :ok
        {:error, error} -> raise error
      end
    end)
  end
end
