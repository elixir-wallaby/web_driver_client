defmodule WebDriverClient.IntegrationTesting.Scenarios do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario

  @scenarios [
    %Scenario{
      driver: :chromedriver,
      browser: :chrome,
      session_configuration_name: :desired_capabilities_headless
    },
    %Scenario{
      driver: :chromedriver,
      browser: :chrome,
      session_configuration_name: :capabilities_headless
    },
    %Scenario{
      driver: :phantomjs,
      browser: :phantomjs,
      session_configuration_name: :desired_capabilities
    },
    %Scenario{
      driver: :selenium,
      browser: :firefox,
      session_configuration_name: :desired_capabilities_firefox
    },
    %Scenario{
      driver: :selenium,
      browser: :chrome,
      session_configuration_name: :desired_capabilities_chrome
    }
  ]

  @spec all :: [Scenario.t()]
  def all, do: @scenarios

  @spec get_config(Scenario.t()) :: Config.t()
  def get_config(%Scenario{driver: driver}) do
    Config.build(base_url: get_base_url(driver))
  end

  @spec get_start_session_payload(Scenario.t()) :: map()
  def get_start_session_payload(%Scenario{
        driver: :chromedriver,
        session_configuration_name: :desired_capabilities_headless
      }) do
    %{
      desiredCapabilities: %{
        chromeOptions: %{
          args: [
            "--no-sandbox",
            "window-size=1280,800",
            "--disable-gpu",
            "--headless",
            "--fullscreen"
          ]
        }
      }
    }
  end

  def get_start_session_payload(%Scenario{
        driver: :chromedriver,
        session_configuration_name: :capabilities_headless
      }) do
    %{
      capabilities: %{
        alwaysMatch: %{
          "goog:chromeOptions": %{
            args: [
              "--no-sandbox",
              "window-size=1280,800",
              "--disable-gpu",
              "--headless",
              "--fullscreen"
            ]
          }
        }
      }
    }
  end

  def get_start_session_payload(%Scenario{
        driver: :phantomjs,
        session_configuration_name: :desired_capabilities
      }) do
    %{
      desiredCapabilities: %{}
    }
  end

  def get_start_session_payload(%Scenario{
        driver: :selenium,
        session_configuration_name: :desired_capabilities_firefox
      }) do
    %{
      desiredCapabilities: %{
        "browserName" => "firefox"
      }
    }
  end

  def get_start_session_payload(%Scenario{
        driver: :selenium,
        session_configuration_name: :desired_capabilities_chrome
      }) do
    %{
      desiredCapabilities: %{
        "browserName" => "chrome"
      }
    }
  end

  @spec get_base_url(atom) :: String.t()
  defp get_base_url(driver) do
    driver_specific_env_var =
      driver
      |> to_string()
      |> String.upcase()
      |> Kernel.<>("_BASE_URL")

    System.get_env(driver_specific_env_var) || System.get_env("WEBDRIVER_BASE_URL") ||
      get_default_base_url(driver)
  end

  defp get_default_base_url(:chromedriver), do: "http://localhost:9515"
  defp get_default_base_url(:phantomjs), do: "http://localhost:8910"
  defp get_default_base_url(:selenium), do: "http://localhost:4444/wd/hub"
end
