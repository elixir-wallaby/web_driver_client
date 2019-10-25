defmodule WebDriverClient.Integration.WindowTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestServer
  alias WebDriverClient.Session
  alias WebDriverClient.Size

  require WebDriverClient.IntegrationTesting.TestGenerator

  @moduletag :capture_log
  @moduletag :integration

  TestGenerator.generate_describe_per_scenario do
    test "manipulating windows", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      url = TestServer.get_base_url()

      :ok = WebDriverClient.navigate_to(session, url)

      assert {:ok, %Size{}} = WebDriverClient.fetch_window_size(session)

      width = 500
      height = 600

      assert :ok = WebDriverClient.set_window_size(session, width: width, height: height)

      assert {:ok, %Size{width: ^width, height: ^height}} =
               WebDriverClient.fetch_window_size(session)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
