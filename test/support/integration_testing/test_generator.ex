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

        describe_name =
          unquote(__MODULE__).__scenario_description__(scenario, unquote(__CALLER__.line))

        integration_test_driver_configuration_name = "#{driver}-#{configuration_name}"
        integration_test_driver_browser = "#{driver}-#{browser}"

        describe describe_name do
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

  @doc false
  def __scenario_description__(scenario, line_number) do
    %Scenario{
      browser: browser,
      driver: driver,
      protocol: protocol,
      session_configuration_name: session_configuration_name
    } = scenario

    "Scenario(#{browser}/#{driver}/#{protocol}/#{session_configuration_name}/line=#{line_number})"
  end
end
