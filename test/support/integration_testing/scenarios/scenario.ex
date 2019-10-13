defmodule WebDriverClient.IntegrationTesting.Scenarios.Scenario do
  @moduledoc false

  @type t :: %__MODULE__{
          driver: atom,
          browser: atom,
          session_configuration_name: atom
        }

  defstruct [
    :driver,
    :browser,
    :session_configuration_name
  ]
end
