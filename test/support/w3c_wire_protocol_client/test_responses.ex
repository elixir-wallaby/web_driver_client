defmodule WebDriverClient.W3CWireProtocolClient.TestResponses do
  @moduledoc false
  use ExUnitProperties

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  def start_session_response do
    constant(%{
      "value" => %{
        "capabilities" => %{
          "acceptInsecureCerts" => false,
          "browserName" => "chrome",
          "browserVersion" => "77.0.3865.120",
          "chrome" => %{
            "chromedriverVersion" =>
              "77.0.3865.40 (f484704e052e0b556f8030b65b953dce96503217-refs/branch-heads/3865@{#442})",
            "userDataDir" =>
              "/var/folders/mn/dxbldtrx3jv0q_hnnz8kfmf00000gn/T/.com.google.Chrome.QNPU8L"
          },
          "goog:chromeOptions" => %{"debuggerAddress" => "localhost:62775"},
          "networkConnectionEnabled" => false,
          "pageLoadStrategy" => "normal",
          "platformName" => "mac os x",
          "proxy" => %{},
          "setWindowRect" => true,
          "strictFileInteractability" => false,
          "timeouts" => %{"implicit" => 0, "pageLoad" => 300_000, "script" => 30_000},
          "unhandledPromptBehavior" => "dismiss and notify"
        },
        "sessionId" => "882326fd74ae485962d435e265c51fbd"
      }
    })
    |> map(&Jason.encode!/1)
  end

  def fetch_sessions_response do
    constant(%{
      "sessionId" => "",
      "status" => 0,
      "value" => [
        %{
          "capabilities" => %{
            "acceptInsecureCerts" => false,
            "browserName" => "chrome",
            "browserVersion" => "77.0.3865.120",
            "chrome" => %{
              "chromedriverVersion" =>
                "77.0.3865.40 (f484704e052e0b556f8030b65b953dce96503217-refs/branch-heads/3865@{#442})",
              "userDataDir" =>
                "/var/folders/mn/dxbldtrx3jv0q_hnnz8kfmf00000gn/T/.com.google.Chrome.Iw15gJ"
            },
            "goog:chromeOptions" => %{
              "debuggerAddress" => "localhost:63322"
            },
            "networkConnectionEnabled" => false,
            "pageLoadStrategy" => "normal",
            "platformName" => "mac os x",
            "proxy" => %{},
            "setWindowRect" => true,
            "strictFileInteractability" => false,
            "timeouts" => %{
              "implicit" => 0,
              "pageLoad" => 300_000,
              "script" => 30_000
            },
            "unhandledPromptBehavior" => "dismiss and notify"
          },
          "id" => "9e8adbbf4187003d9e0d9b2934a9c5d0"
        }
      ]
    })
    |> map(&Jason.encode!/1)
  end

  def end_session_response do
    constant(%{"value" => nil}) |> map(&Jason.encode!/1)
  end

  def error_response do
    error_reason = "invalid selector"

    %{
      "error" => constant(error_reason),
      "message" =>
        scale(
          string(:printable),
          &trunc(:math.log(&1))
        ),
      "stacktrace" =>
        scale(
          string(:printable),
          &trunc(:math.log(&1))
        )
    }
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def navigate_to_response do
    constant(%{"value" => nil}) |> map(&Jason.encode!/1)
  end

  def fetch_window_rect_response do
    window_rect_response() |> map(&Jason.encode!/1)
  end

  def set_window_rect_response do
    window_rect_response() |> map(&Jason.encode!/1)
  end

  def fetch_current_url_response do
    fixed_map(%{"value" => url()}) |> map(&Jason.encode!/1)
  end

  def fetch_title_response do
    %{"value" => string(:alphanumeric, max_length: 5)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_alert_text_response do
    %{"value" => string(:alphanumeric, max_length: 5)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def accept_alert_response do
    %{"value" => nil} |> constant() |> map(&Jason.encode!/1)
  end

  def dismiss_alert_response do
    %{"value" => nil} |> constant() |> map(&Jason.encode!/1)
  end

  def fetch_page_source_response do
    %{"value" => string(:alphanumeric, max_length: 5)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def find_element_response do
    %{"value" => element()}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def find_elements_response(list_opts \\ [max_length: 10]) do
    %{"value" => list_of(element(), list_opts)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_log_types_response do
    %{"value" => list_of(string(:alphanumeric), max_length: 10)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_logs_response do
    %{"value" => list_of(log_entry(), max_length: 10)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_element_displayed_response do
    %{"value" => boolean()}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_element_attribute_response do
    %{"value" => string(:alphanumeric, min_length: 1, max_length: 5)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_element_text_response do
    %{"value" => string(:alphanumeric, min_length: 1, max_length: 5)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def click_element_response do
    %{"value" => nil} |> constant() |> map(&Jason.encode!/1)
  end

  def clear_element_response do
    %{"value" => nil} |> constant() |> map(&Jason.encode!/1)
  end

  def log_entry do
    fixed_map(%{
      "timestamp" => recent_timestamp(),
      "level" => log_level(),
      "message" => log_message()
    })
  end

  def log_message do
    string(:printable)
  end

  def log_level do
    string(:alphanumeric, min_length: 1, max_length: 10)
  end

  def log_type do
    string(:alphanumeric, min_length: 1, max_length: 10)
  end

  def element do
    fixed_map(%{@web_element_identifier => string(:ascii, min_length: 1, max_length: 20)})
  end

  defp window_rect_response do
    fixed_map(%{
      "value" =>
        fixed_map(%{
          "x" => integer(),
          "y" => integer(),
          "width" => integer(0..1000),
          "height" => integer(0..1000)
        })
    })
  end

  defp url do
    constant("http://foo.com")
  end

  defp recent_timestamp do
    map(
      integer(),
      &(DateTime.utc_now()
        |> DateTime.to_unix(:millisecond)
        |> Kernel.+(&1))
    )
  end
end
