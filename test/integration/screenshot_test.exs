defmodule WebDriverClient.Integration.ScreenshotTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestPages.InteractionsPage
  alias WebDriverClient.Session

  require TestGenerator

  @moduletag :integration
  @moduletag :capture_log

  TestGenerator.generate_describe_per_scenario do
    test "taking a screenshot", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(config, payload)

      ensure_session_is_closed(session)

      :ok = WebDriverClient.navigate_to(session, InteractionsPage.url())

      {:ok, png_data} = WebDriverClient.take_screenshot(session)

      assert_is_png(png_data)
    end
  end

  # PNG binary checking from here: https://zohaib.me/binary-pattern-matching-in-elixir/
  @png_prefix <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>

  defp assert_is_png(@png_prefix <> _rest), do: :ok

  defp assert_is_png(data) do
    flunk("""
    Data does not have the required png prefix

    Required prefix: #{inspect(@png_prefix)}

    #{inspect(data)}
    """)
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end
