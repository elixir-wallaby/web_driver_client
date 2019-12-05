defmodule WebDriverClient.IntegrationTesting.Scenarios do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.IntegrationTesting.Scenarios.Scenario

  @scenarios [
    %Scenario{
      driver: :chromedriver,
      browser: :chrome,
      session_configuration_name: :json_headless,
      protocol: :jwp
    },
    %Scenario{
      driver: :chromedriver,
      browser: :chrome,
      session_configuration_name: :w3c_headless,
      protocol: :w3c
    },
    %Scenario{
      driver: :phantomjs,
      browser: :phantomjs,
      session_configuration_name: :json,
      protocol: :jwp
    },
    #
    # Selenium 3 with Firefox (or at least the
    # underlying geckodriver) does not support JWP
    #
    # %Scenario{
    #   driver: :selenium_3,
    #   browser: :firefox,
    #   session_configuration_name: :json_firefox,
    #   protocol: :jwp
    # },
    %Scenario{
      driver: :selenium_3,
      browser: :firefox,
      session_configuration_name: :w3c_firefox,
      protocol: :w3c
    },
    %Scenario{
      driver: :selenium_3,
      browser: :chrome,
      session_configuration_name: :json_chrome,
      protocol: :jwp
    },
    %Scenario{
      driver: :selenium_3,
      browser: :chrome,
      session_configuration_name: :w3c_chrome,
      protocol: :w3c
    },
    %Scenario{
      driver: :selenium_2,
      browser: :chrome,
      session_configuration_name: :json_chrome,
      protocol: :jwp
    },
    %Scenario{
      driver: :selenium_2,
      browser: :firefox,
      session_configuration_name: :json_firefox,
      protocol: :jwp
    }
  ]

  @spec all :: [Scenario.t()]
  def all, do: @scenarios

  @spec get_config(Scenario.t()) :: Config.t()
  def get_config(%Scenario{driver: driver, protocol: protocol}) do
    Config.build(base_url: get_base_url(driver), protocol: protocol, debug: true)
  end

  @spec get_start_session_payload(Scenario.t()) :: map()
  def get_start_session_payload(%Scenario{
        driver: :chromedriver,
        session_configuration_name: :json_headless
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
        session_configuration_name: :w3c_headless
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
        session_configuration_name: :json
      }) do
    %{
      desiredCapabilities: %{}
    }
  end

  def get_start_session_payload(%Scenario{
        driver: driver,
        session_configuration_name: :json_firefox
      })
      when driver in [:selenium_2, :selenium_3] do
    %{
      desiredCapabilities: %{
        "browserName" => "firefox",
        "moz:firefoxOptions" => %{
          "args" => [
            "-headless"
          ]
        }
      }
    }
  end

  def get_start_session_payload(%Scenario{
        driver: :selenium_3,
        session_configuration_name: :w3c_firefox
      }) do
    %{
      capabilities: %{
        alwaysMatch: %{
          "moz:firefoxOptions" => %{
            "args" => [
              "-headless"
            ]
          }
        }
      }
    }
  end

  def get_start_session_payload(%Scenario{
        driver: driver,
        session_configuration_name: :json_chrome
      })
      when driver in [:selenium_2, :selenium_3] do
    %{
      desiredCapabilities: %{
        "browserName" => "chrome",
        "goog:chromeOptions" => %{
          "w3c" => false
        }
      }
    }
  end

  def get_start_session_payload(%Scenario{
        driver: :selenium_3,
        session_configuration_name: :w3c_chrome
      }) do
    %{
      capabilities: %{
        alwaysMatch: %{
          "browserName" => "chrome",
          "goog:chromeOptions" => %{
            "args" => [
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
  defp get_default_base_url(:selenium_3), do: "http://localhost:4444/wd/hub"
  defp get_default_base_url(:selenium_2), do: "http://localhost:4444/wd/hub"
end
