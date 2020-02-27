defmodule WebDriverClient.Integration.StatusTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.ConnectionError
  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.ProtocolMismatchError
  alias WebDriverClient.ServerStatus

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  TestGenerator.generate_describe_per_scenario do
    test "checking server status", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)

      assert {:ok, %ServerStatus{ready?: true}} =
               config
               |> WebDriverClient.fetch_server_status()
               |> unwrap_protocol_mismatch_error()

      assert {:error, %ConnectionError{}} =
               config
               |> struct!(base_url: "http://does-not-exist-123")
               |> WebDriverClient.fetch_server_status()
    end
  end

  defp unwrap_protocol_mismatch_error({:error, %ProtocolMismatchError{response: response}}),
    do: response

  defp unwrap_protocol_mismatch_error(response), do: response
end
