defmodule WebDriverClient.JSONWireProtocolClient.TestResponses do
  @moduledoc false
  use ExUnitProperties

  def fetch_sessions_response do
    constant(%{
      "sessionId" => nil,
      "status" => 0,
      "value" => [
        %{
          "capabilities" => %{
            "acceptSslCerts" => false,
            "applicationCacheEnabled" => false,
            "browserConnectionEnabled" => false,
            "browserName" => "phantomjs",
            "cssSelectorsEnabled" => true,
            "databaseEnabled" => false,
            "driverName" => "ghostdriver",
            "driverVersion" => "1.2.0",
            "handlesAlerts" => false,
            "javascriptEnabled" => true,
            "locationContextEnabled" => false,
            "nativeEvents" => true,
            "platform" => "mac-unknown-64bit",
            "proxy" => %{"proxyType" => "direct"},
            "rotatable" => false,
            "takesScreenshot" => true,
            "version" => "2.1.1",
            "webStorageEnabled" => false
          },
          "id" => "89243fd0-2225-11ea-9a6f-8df630e6d233"
        }
      ]
    })
    |> map(&Jason.encode!/1)
  end

  def end_session_response do
    constant(%{"value" => nil}) |> map(&Jason.encode!/1)
  end

  def navigate_to_response do
    constant(%{"value" => nil}) |> map(&Jason.encode!/1)
  end

  def fetch_window_size_response do
    window_size_response() |> map(&Jason.encode!/1)
  end

  def set_window_size_response do
    blank_value_response() |> map(&Jason.encode!/1)
  end

  def fetch_current_url_response do
    fixed_map(%{"value" => url()}) |> map(&Jason.encode!/1)
  end

  def find_elements_response do
    %{"value" => list_of(element(), max_length: 10)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_log_types_response do
    %{"value" => list_of(log_type(), max_length: 10)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def fetch_logs_response do
    %{"value" => list_of(log_entry(), max_length: 10)}
    |> fixed_map()
    |> map(&Jason.encode!/1)
  end

  def log_entry do
    gen all required_data <-
              fixed_map(%{
                "timestamp" => recent_timestamp(),
                "level" => log_level(),
                "message" => log_message()
              }),
            optional_data <-
              optional_map(%{
                "source" => log_source()
              }) do
      Map.merge(required_data, optional_data)
    end
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

  def log_source do
    string(:alphanumeric, min_length: 1, max_length: 10)
  end

  defp blank_value_response do
    constant(%{"value" => nil})
  end

  def element do
    fixed_map(%{"ELEMENT" => string(:ascii, min_length: 1, max_length: 20)})
  end

  defp window_size_response do
    fixed_map(%{
      "value" =>
        fixed_map(%{
          "width" => integer(0..1000),
          "height" => integer(0..1000)
        })
    })
  end

  defp url do
    constant("http://example.com")
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
