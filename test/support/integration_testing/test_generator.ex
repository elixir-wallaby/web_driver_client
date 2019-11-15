defmodule WebDriverClient.IntegrationTesting.TestGenerator do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario

  defmacro generate_describe_per_scenario(opts \\ [], do: block) when is_list(opts) do
    default_scenarios = Scenarios.all()

    quote do
      unquote(opts)
      |> Keyword.get(:scenarios, unquote(Macro.escape(default_scenarios)))
      |> Enum.each(fn scenario ->
        %Scenario{
          driver: driver,
          browser: browser,
          session_configuration_name: configuration_name
        } = scenario

        integration_test_driver_configuration_name = "#{driver}-#{configuration_name}"
        integration_test_driver_browser = "#{driver}-#{browser}"

        describe inspect(scenario) do
          @describetag scenario: scenario
          @describetag integration_test_driver: to_string(driver)
          @describetag integration_test_driver_browser: integration_test_driver_browser
          @describetag integration_test_driver_configuration_name:
                         integration_test_driver_configuration_name

          unquote(block)
        end
      end)
    end
  end
end
