defmodule WebDriverClient.JSONWireProtocolClient.TestResponses do
  @moduledoc false
  use ExUnitProperties

  def start_session_response do
    %{
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
    }
    |> constant()
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_sessions_response do
    [
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
    |> constant()
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def end_session_response do
    nil
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def navigate_to_response do
    nil
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_window_size_response do
    %{
      "width" => integer(0..1000),
      "height" => integer(0..1000)
    }
    |> fixed_map()
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def set_window_size_response do
    nil
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_current_url_response do
    url()
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_title_response do
    string(:alphanumeric, max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_alert_text_response do
    string(:alphanumeric, max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def accept_alert_response do
    nil
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def dismiss_alert_response do
    nil
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_page_source_response do
    string(:alphanumeric, max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def find_element_response do
    element()
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def find_elements_response(list_opts \\ [max_length: 10]) do
    element()
    |> list_of(list_opts)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_log_types_response do
    log_type()
    |> list_of(max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_logs_response do
    log_entry()
    |> list_of(max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_element_displayed_response do
    boolean()
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_element_attribute_response do
    :alphanumeric
    |> string(min_length: 0, max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def fetch_element_text_response do
    :alphanumeric
    |> string(min_length: 0, max_length: 10)
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def click_element_response do
    nil
    |> jwp_response()
    |> map(&Jason.encode!/1)
  end

  def clear_element_response do
    nil
    |> jwp_response()
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

  def element do
    fixed_map(%{"ELEMENT" => string(:ascii, min_length: 1, max_length: 20)})
  end

  def jwp_response(value, opts \\ []) do
    status = Keyword.get(opts, :status, constant(0))

    fixed_map(%{
      "sessionId" => unshrinkable(session_id()),
      "status" => status,
      "value" => value
    })
  end

  def status_int do
    integer(0..40)
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

  def session_id do
    string(:alphanumeric, min_length: 1, max_length: 30)
  end
end
