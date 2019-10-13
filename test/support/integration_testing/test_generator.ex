defmodule WebDriverClient.IntegrationTesting.TestGenerator do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario

  defmacro generate_describe_per_scenario(opts \\ [], do: block) when is_list(opts) do
    scenarios =
      case Keyword.fetch(opts, :scenarios) do
        {:ok, scenarios_ast} ->
          {scenarios, _} = Code.eval_quoted(scenarios_ast, [], __CALLER__)
          scenarios

        :error ->
          Scenarios.all()
      end

    Enum.map(scenarios, fn scenario ->
      %Scenario{
        driver: driver,
        browser: browser,
        session_configuration_name: configuration_name
      } = scenario

      integration_test_driver_configuration_name = "#{driver}-#{configuration_name}"
      integration_test_driver_browser = "#{driver}-#{browser}"

      quote do
        describe unquote(inspect(scenario)) do
          @describetag scenario: unquote(Macro.escape(scenario))
          @describetag integration_test_driver: unquote(to_string(driver))
          @describetag integration_test_driver_browser: unquote(integration_test_driver_browser)
          @describetag integration_test_driver_configuration_name:
                         unquote(integration_test_driver_configuration_name)

          unquote(block)
        end
      end
    end)
  end
end
