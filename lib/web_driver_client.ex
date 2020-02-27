defmodule WebDriverClient do
  @moduledoc """
  Webdriver API client.
  """

  import WebDriverClient.CompatibilityMacros
  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.Cookie
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.Commands, as: JWPCommands
  alias WebDriverClient.KeyCodes
  alias WebDriverClient.LogEntry
  alias WebDriverClient.ProtocolMismatchError
  alias WebDriverClient.ServerStatus
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.Commands, as: W3CCommands
  alias WebDriverClient.WebDriverError

  @type protocol :: Config.protocol()
  @type url :: String.t()
  @type attribute_name :: String.t()
  @type property_name :: String.t()
  @type reason :: ProtocolMismatchError.t() | basic_reason
  @type basic_reason ::
          ConnectionError.t()
          | UnexpectedResponseError.t()
          | WebDriverError.t()

  @doc """
  Starts a new session
  """
  doc_metadata subject: :sessions
  @spec start_session(Config.t(), map()) :: {:ok, Session.t()} | {:error, reason}
  def start_session(%Config{protocol: protocol} = config, payload) when is_map(payload) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.StartSession.send_request(config, payload) end,
             w3c: fn -> W3CCommands.StartSession.send_request(config, payload) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.StartSession.parse_response(&1, config),
        w3c: &W3CCommands.StartSession.parse_response(&1, config)
      )
    end
  end

  @doc """
  Returns the list of sessions
  """
  doc_metadata subject: :sessions
  @spec fetch_sessions(Config.t()) :: {:ok, [Session.t()]} | {:error, reason}
  def fetch_sessions(%Config{protocol: protocol} = config) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchSessions.send_request(config) end,
             w3c: fn -> W3CCommands.FetchSessions.send_request(config) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchSessions.parse_response(&1, config),
        w3c: &W3CCommands.FetchSessions.parse_response(&1, config)
      )
    end
  end

  @doc """
  Ends a session
  """
  doc_metadata subject: :sessions
  @spec end_session(Session.t()) :: :ok | {:error, reason}
  def end_session(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.EndSession.send_request(session) end,
             w3c: fn -> W3CCommands.EndSession.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.EndSession.parse_response/1,
        w3c: &W3CCommands.EndSession.parse_response/1
      )
    end
  end

  @doc """
  Navigates the browser to the given url
  """
  doc_metadata subject: :navigation
  @spec navigate_to(Session.t(), url) :: :ok | {:error, reason}

  def navigate_to(%Session{config: %Config{protocol: protocol}} = session, url)
      when is_url(url) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.NavigateTo.send_request(session, url) end,
             w3c: fn -> W3CCommands.NavigateTo.send_request(session, url) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.NavigateTo.parse_response/1,
        w3c: &W3CCommands.NavigateTo.parse_response/1
      )
    end
  end

  @doc """
  Returns the web browsers current url
  """
  doc_metadata subject: :navigation
  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, reason}
  def fetch_current_url(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchCurrentURL.send_request(session) end,
             w3c: fn -> W3CCommands.FetchCurrentURL.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchCurrentURL.parse_response/1,
        w3c: &W3CCommands.FetchCurrentURL.parse_response/1
      )
    end
  end

  @doc """
  Returns page title of the top-most window.

  This is the equivalent of calling `document.title`.
  """
  doc_metadata subject: :navigation
  @spec fetch_title(Session.t()) :: {:ok, String.t()} | {:error, reason}
  def fetch_title(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchTitle.send_request(session) end,
             w3c: fn -> W3CCommands.FetchTitle.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchTitle.parse_response/1,
        w3c: &W3CCommands.FetchTitle.parse_response/1
      )
    end
  end

  @doc """
  Returns page source of the top-most window.
  """
  doc_metadata subject: :navigation
  @spec fetch_page_source(Session.t()) :: {:ok, String.t()} | {:error, reason}
  def fetch_page_source(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchPageSource.send_request(session) end,
             w3c: fn -> W3CCommands.FetchPageSource.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchPageSource.parse_response/1,
        w3c: &W3CCommands.FetchPageSource.parse_response/1
      )
    end
  end

  @doc """
  Returns the size of the current window
  """
  @spec fetch_window_size(Session.t()) :: {:ok, Size.t()} | {:error, reason}
  def fetch_window_size(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchWindowSize.send_request(session) end,
             w3c: fn -> W3CCommands.FetchWindowRect.send_request(session) end
           ) do
      parse_with_fallbacks(
        http_response,
        protocol,
        [
          jwp: &JWPCommands.FetchWindowSize.parse_response/1,
          w3c: &W3CCommands.FetchWindowRect.parse_response/1
        ],
        fn
          {:ok, size} -> {:ok, to_size(size)}
          {:error, error} -> {:error, to_error(error)}
        end
      )
    end
  end

  @type element_location_strategy :: :css_selector | :xpath
  @type element_selector :: String.t()

  @doc """
  Finds the first element using the given search strategy

  If no element is found, a `WebDriverClient.WebDriverError`
  is returned
  """
  doc_metadata subject: :elements

  @spec find_element(Session.t(), element_location_strategy, element_selector) ::
          {:ok, Element.t()} | {:error, reason}
  def find_element(
        %Session{config: %Config{protocol: protocol}} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.FindElement.send_request(
                 session,
                 element_location_strategy,
                 element_selector
               )
             end,
             w3c: fn ->
               W3CCommands.FindElement.send_request(
                 session,
                 element_location_strategy,
                 element_selector
               )
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FindElement.parse_response/1,
        w3c: &W3CCommands.FindElement.parse_response/1
      )
    end
  end

  @doc """
  Finds the elements using the given search strategy
  """
  doc_metadata subject: :elements

  @spec find_elements(Session.t(), element_location_strategy, element_selector) ::
          {:ok, [Element.t()]} | {:error, reason}
  def find_elements(
        %Session{config: %Config{protocol: protocol}} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.FindElements.send_request(
                 session,
                 element_location_strategy,
                 element_selector
               )
             end,
             w3c: fn ->
               W3CCommands.FindElements.send_request(
                 session,
                 element_location_strategy,
                 element_selector
               )
             end
           ) do
      parse_with_fallbacks(
        http_response,
        protocol,
        jwp: &JWPCommands.FindElements.parse_response/1,
        w3c: &W3CCommands.FindElements.parse_response/1
      )
    end
  end

  @doc """
  Finds elements that are children of the given element
  """
  doc_metadata subject: :elements

  @spec find_elements_from_element(
          Session.t(),
          Element.t(),
          element_location_strategy,
          element_selector
        ) :: {:ok, [Element.t()] | {:error, reason}}
  def find_elements_from_element(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.FindElementsFromElement.send_request(
                 session,
                 element,
                 element_location_strategy,
                 element_selector
               )
             end,
             w3c: fn ->
               W3CCommands.FindElementsFromElement.send_request(
                 session,
                 element,
                 element_location_strategy,
                 element_selector
               )
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FindElementsFromElement.parse_response/1,
        w3c: &W3CCommands.FindElementsFromElement.parse_response/1
      )
    end
  end

  @doc """
  Fetches the currently active (focused) element
  """
  doc_metadata subject: :elements

  @spec fetch_active_element(Session.t()) :: {:ok, Element.t()} | {:error, reason}
  def fetch_active_element(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchActiveElement.send_request(session) end,
             w3c: fn -> W3CCommands.FetchActiveElement.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchActiveElement.parse_response/1,
        w3c: &W3CCommands.FetchActiveElement.parse_response/1
      )
    end
  end

  @type size_opt :: {:width, pos_integer} | {:height, pos_integer}

  @doc """
  Sets the size of the window
  """
  @spec set_window_size(Session.t(), [size_opt]) :: :ok | {:error, reason}
  def set_window_size(%Session{config: %Config{protocol: protocol}} = session, opts \\ []) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.SetWindowSize.send_request(session, opts) end,
             w3c: fn -> W3CCommands.SetWindowRect.send_request(session, opts) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.SetWindowSize.parse_response/1,
        w3c: &W3CCommands.SetWindowRect.parse_response/1
      )
    end
  end

  @type log_type :: String.t()

  @doc """
  Fetches the log types from the server
  """
  doc_metadata subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [log_type]} | {:error, reason()}
  def fetch_log_types(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchLogTypes.send_request(session) end,
             w3c: fn -> W3CCommands.FetchLogTypes.send_request(session) end
           ) do
      parse_with_fallbacks(
        http_response,
        protocol,
        jwp: &JWPCommands.FetchLogTypes.parse_response/1,
        w3c: &W3CCommands.FetchLogTypes.parse_response/1
      )
    end
  end

  @doc """
  Fetches log entries for the requested log type.
  """
  doc_metadata subject: :logging
  @spec fetch_logs(Session.t(), log_type) :: {:ok, [LogEntry.t()]} | {:error, reason()}
  def fetch_logs(session, log_type)

  def fetch_logs(%Session{config: %Config{protocol: protocol}} = session, log_type)
      when is_binary(log_type) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchLogs.send_request(session, log_type) end,
             w3c: fn -> W3CCommands.FetchLogs.send_request(session, log_type) end
           ) do
      parse_with_fallbacks(
        http_response,
        protocol,
        [
          jwp: &JWPCommands.FetchLogs.parse_response/1,
          w3c: &W3CCommands.FetchLogs.parse_response/1
        ],
        fn
          {:ok, log_entries} -> {:ok, Enum.map(log_entries, &to_log_entry/1)}
          {:error, error} -> {:error, to_error(error)}
        end
      )
    end
  end

  @doc """
  Sends a request to the server to see if an element
  is displayed
  """
  doc_metadata subject: :elements

  @spec fetch_element_displayed(Session.t(), Element.t()) :: {:ok, boolean} | {:error, reason}
  def fetch_element_displayed(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchElementDisplayed.send_request(session, element) end,
             w3c: fn -> W3CCommands.FetchElementDisplayed.send_request(session, element) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchElementDisplayed.parse_response/1,
        w3c: &W3CCommands.FetchElementDisplayed.parse_response/1
      )
    end
  end

  @doc """
  Fetches the value of an element's attribute
  """
  doc_metadata subject: :elements

  @spec fetch_element_attribute(Session.t(), Element.t(), attribute_name) ::
          {:ok, String.t()} | {:error, reason}
  def fetch_element_attribute(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element,
        attribute_name
      )
      when is_attribute_name(attribute_name) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.FetchElementAttribute.send_request(session, element, attribute_name)
             end,
             w3c: fn ->
               W3CCommands.FetchElementAttribute.send_request(session, element, attribute_name)
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchElementAttribute.parse_response/1,
        w3c: &W3CCommands.FetchElementAttribute.parse_response/1
      )
    end
  end

  @doc """
  Fetches the value of an element's property

  Only supported using `:w3c` protocol.
  """
  doc_metadata subject: :elements

  @spec fetch_element_property(Session.t(), Element.t(), property_name) ::
          {:ok, String.t()} | {:error, reason}
  def fetch_element_property(%Session{config: %Config{protocol: :jwp}}, %Element{}, property_name)
      when is_property_name(property_name) do
    {:error, WebDriverError.exception(reason: :unsupported_operation)}
  end

  def fetch_element_property(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element,
        property_name
      )
      when is_property_name(property_name) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             w3c: fn ->
               W3CCommands.FetchElementProperty.send_request(session, element, property_name)
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        w3c: &W3CCommands.FetchElementProperty.parse_response/1
      )
    end
  end

  @doc """
  Fetches the visitble text of an element
  """
  doc_metadata subject: :elements

  @spec fetch_element_text(Session.t(), Element.t()) :: {:ok, String.t()} | {:error, reason}
  def fetch_element_text(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.FetchElementText.send_request(session, element)
             end,
             w3c: fn ->
               W3CCommands.FetchElementText.send_request(session, element)
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchElementText.parse_response/1,
        w3c: &W3CCommands.FetchElementText.parse_response/1
      )
    end
  end

  @doc """
  Clicks an element
  """
  doc_metadata subject: :elements

  @spec click_element(Session.t(), Element.t()) :: :ok | {:error, reason}
  def click_element(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.ClickElement.send_request(session, element)
             end,
             w3c: fn ->
               W3CCommands.ClickElement.send_request(session, element)
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.ClickElement.parse_response/1,
        w3c: &W3CCommands.ClickElement.parse_response/1
      )
    end
  end

  @doc """
  Clears the value of a text input or text area element
  """
  doc_metadata subject: :elements

  @spec clear_element(Session.t(), Element.t()) :: :ok | {:error, reason}
  def clear_element(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn ->
               JWPCommands.ClearElement.send_request(session, element)
             end,
             w3c: fn ->
               W3CCommands.ClearElement.send_request(session, element)
             end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.ClearElement.parse_response/1,
        w3c: &W3CCommands.ClearElement.parse_response/1
      )
    end
  end

  @type key_code :: unquote_splicing([KeyCodes.key_code_atoms_union()])
  @type keystroke :: String.t() | key_code
  @type keys :: keystroke | [keystroke]

  @doc """
  Sends a sequence of keystrokes to an element
  """
  doc_metadata subject: :elements

  @spec send_keys_to_element(Session.t(), Element.t(), keys) :: :ok | {:error, reason}
  def send_keys_to_element(
        %Session{config: %Config{protocol: protocol}} = session,
        %Element{} = element,
        keys
      ) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.SendKeysToElement.send_request(session, element, keys) end,
             w3c: fn -> W3CCommands.SendKeysToElement.send_request(session, element, keys) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.SendKeysToElement.parse_response/1,
        w3c: &W3CCommands.SendKeysToElement.parse_response/1
      )
    end
  end

  @doc """
  Sends a sequence of keystrokes to the currently active element.

  Only supported with `:jwp` protocol. Prefer `send_keys_to_element/3` for
  improved compatibility.
  """
  doc_metadata subject: :elements

  @spec send_keys(Session.t(), keys) :: :ok | {:error, reason}
  def send_keys(%Session{config: %Config{protocol: :w3c}}, _keys) do
    {:error, WebDriverError.exception(reason: :unsupported_operation)}
  end

  def send_keys(%Session{config: %Config{protocol: protocol}} = session, keys) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.SendKeys.send_request(session, keys) end
           ) do
      parse_with_fallbacks(http_response, protocol, jwp: &JWPCommands.SendKeys.parse_response/1)
    end
  end

  @doc """
  Fetches the text from the currently active alert.
  """
  doc_metadata subject: :alerts
  @spec fetch_alert_text(Session.t()) :: :ok | {:error, reason}
  def fetch_alert_text(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchAlertText.send_request(session) end,
             w3c: fn -> W3CCommands.FetchAlertText.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.FetchAlertText.parse_response/1,
        w3c: &W3CCommands.FetchAlertText.parse_response/1
      )
    end
  end

  @doc """
  Accepts the currently active alert dialog.

  Usually this is the equivalent to clicking ok on a dialog.
  """
  doc_metadata subject: :alerts
  @spec accept_alert(Session.t()) :: :ok | {:error, reason}
  def accept_alert(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.AcceptAlert.send_request(session) end,
             w3c: fn -> W3CCommands.AcceptAlert.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.AcceptAlert.parse_response/1,
        w3c: &W3CCommands.AcceptAlert.parse_response/1
      )
    end
  end

  @doc """
  Dismisses the currently active alert dialog.

  For `confirm()` and `prompt()` dialogs, this is equivalent to
  clicking the 'Cancel' button. For `alert()` dialogs, this is
  equivalent to clicking the 'OK' button.
  """
  doc_metadata subject: :alerts
  @spec dismiss_alert(Session.t()) :: :ok | {:error, reason}
  def dismiss_alert(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.DismissAlert.send_request(session) end,
             w3c: fn -> W3CCommands.DismissAlert.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.DismissAlert.parse_response/1,
        w3c: &W3CCommands.DismissAlert.parse_response/1
      )
    end
  end

  @doc """
  Sends keystrokes to the currently active Javascript `prompt` dialog.
  """
  doc_metadata subject: :alerts
  @spec send_alert_text(Session.t(), String.t()) :: :ok | {:error, reason}
  def send_alert_text(%Session{config: %Config{protocol: protocol}} = session, text)
      when is_binary(text) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.SendAlertText.send_request(session, text) end,
             w3c: fn -> W3CCommands.SendAlertText.send_request(session, text) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.SendAlertText.parse_response/1,
        w3c: &W3CCommands.SendAlertText.parse_response/1
      )
    end
  end

  @doc """
  Takes a screenshot of the current page.
  """
  @spec take_screenshot(Session.t()) :: {:ok, binary} | {:error, reason}
  def take_screenshot(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.TakeScreenshot.send_request(session) end,
             w3c: fn -> W3CCommands.TakeScreenshot.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.TakeScreenshot.parse_response/1,
        w3c: &W3CCommands.TakeScreenshot.parse_response/1
      )
    end
  end

  @doc """
  Fetches all cookies visible to the current web page.
  """
  @spec fetch_cookies(Session.t()) :: {:ok, [Cookie.t()]} | {:error, reason}
  def fetch_cookies(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchCookies.send_request(session) end,
             w3c: fn -> W3CCommands.FetchCookies.send_request(session) end
           ) do
      parse_with_fallbacks(
        http_response,
        protocol,
        [
          jwp: &JWPCommands.FetchCookies.parse_response/1,
          w3c: &W3CCommands.FetchCookies.parse_response/1
        ],
        fn
          {:ok, cookies} -> {:ok, Enum.map(cookies, &to_cookie/1)}
          {:error, error} -> {:error, to_error(error)}
        end
      )
    end
  end

  @type set_cookie_opt :: {:domain, Cookie.domain()}

  @doc """
  Sets a cookie
  """
  @spec set_cookie(Session.t(), Cookie.name(), Cookie.value(), [set_cookie_opt]) ::
          :ok | {:error, reason}
  def set_cookie(%Session{config: %Config{protocol: protocol}} = session, name, value, opts \\ [])
      when is_cookie_name(name) and is_cookie_value(value) and is_list(opts) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.SetCookie.send_request(session, name, value, opts) end,
             w3c: fn -> W3CCommands.SetCookie.send_request(session, name, value, opts) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.SetCookie.parse_response/1,
        w3c: &W3CCommands.SetCookie.parse_response/1
      )
    end
  end

  @doc """
  Deletes all cookies visible to the current page
  """
  @spec delete_cookies(Session.t()) :: :ok | {:error, reason}
  def delete_cookies(%Session{config: %Config{protocol: protocol}} = session) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.DeleteCookies.send_request(session) end,
             w3c: fn -> W3CCommands.DeleteCookies.send_request(session) end
           ) do
      parse_with_fallbacks(http_response, protocol,
        jwp: &JWPCommands.DeleteCookies.parse_response/1,
        w3c: &W3CCommands.DeleteCookies.parse_response/1
      )
    end
  end

  @doc """
  Fetches server status
  """
  @spec fetch_server_status(Config.t()) :: {:ok, ServerStatus.t()} | {:error, reason}
  def fetch_server_status(%Config{protocol: protocol} = config) do
    with {:ok, http_response} <-
           send_request_for_protocol(protocol,
             jwp: fn -> JWPCommands.FetchServerStatus.send_request(config) end,
             w3c: fn -> W3CCommands.FetchServerStatus.send_request(config) end
           ) do
      parse_with_fallbacks(
        http_response,
        protocol,
        [
          jwp: &JWPCommands.FetchServerStatus.parse_response/1,
          w3c: &W3CCommands.FetchServerStatus.parse_response/1
        ],
        fn
          {:ok, server_status} -> {:ok, to_server_status(server_status)}
          {:error, error} -> {:error, to_error(error)}
        end
      )
    end
  end

  @spec to_log_entry(JSONWireProtocolClient.LogEntry.t()) :: LogEntry.t()
  defp to_log_entry(%JSONWireProtocolClient.LogEntry{} = log_entry) do
    log_entry
    |> Map.from_struct()
    |> (&struct!(LogEntry, &1)).()
  end

  @spec to_log_entry(W3CWireProtocolClient.LogEntry.t()) :: LogEntry.t()
  defp to_log_entry(%W3CWireProtocolClient.LogEntry{} = log_entry) do
    log_entry
    |> Map.from_struct()
    |> (&struct!(LogEntry, &1)).()
  end

  @spec to_cookie(W3CWireProtocolClient.Cookie.t() | JSONWireProtocolClient.Cookie.t()) ::
          Cookie.t()
  defp to_cookie(%JSONWireProtocolClient.Cookie{} = cookie) do
    cookie
    |> Map.from_struct()
    |> (&struct!(Cookie, &1)).()
  end

  defp to_cookie(%W3CWireProtocolClient.Cookie{} = cookie) do
    cookie
    |> Map.from_struct()
    |> (&struct!(Cookie, &1)).()
  end

  @spec to_server_status(
          W3CWireProtocolClient.ServerStatus.t()
          | JSONWireProtocolClient.ServerStatus.t()
        ) :: ServerStatus.t()
  defp to_server_status(%JSONWireProtocolClient.ServerStatus{} = server_status) do
    server_status
    |> Map.from_struct()
    |> (&struct!(ServerStatus, &1)).()
  end

  defp to_server_status(%W3CWireProtocolClient.ServerStatus{} = server_status) do
    server_status
    |> Map.from_struct()
    |> (&struct!(ServerStatus, &1)).()
  end

  @spec to_size(W3CWireProtocolClient.Rect.t() | JSONWireProtocolClient.Size.t()) :: Size.t()
  defp to_size(%JSONWireProtocolClient.Size{width: width, height: height}),
    do: %Size{width: width, height: height}

  defp to_size(%W3CWireProtocolClient.Rect{width: width, height: height}),
    do: %Size{width: width, height: height}

  defp to_error(%JSONWireProtocolClient.WebDriverError{reason: reason}) do
    reason =
      case reason do
        :no_alert_open_error ->
          :no_such_alert

        reason ->
          reason
      end

    WebDriverError.exception(reason: reason)
  end

  defp to_error(%W3CWireProtocolClient.WebDriverError{reason: reason}) do
    WebDriverError.exception(reason: reason)
  end

  defp to_error(%W3CWireProtocolClient.UnexpectedResponseError{
         reason: reason,
         response_body: response_body
       }) do
    UnexpectedResponseError.exception(
      reason: reason,
      response_body: response_body,
      protocol: :w3c
    )
  end

  defp to_error(%JSONWireProtocolClient.UnexpectedResponseError{
         reason: reason,
         response_body: response_body
       }) do
    UnexpectedResponseError.exception(
      reason: reason,
      response_body: response_body,
      protocol: :jwp
    )
  end

  @spec send_request_for_protocol(protocol, [
          {protocol, (() -> {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()})}
        ]) :: {:ok, HTTPResponse.t()} | {:error, ConnectionError.t()}
  defp send_request_for_protocol(protocol, send_request_fns)
       when is_list(send_request_fns) and is_atom(protocol) do
    send_request_fns
    |> Keyword.fetch!(protocol)
    |> apply([])
  end

  defp parse_with_fallbacks(
         http_response,
         requested_protocol,
         parse_fns,
         normalize_fn \\ &default_normalize_response/1
       )
       when is_list(parse_fns) and is_atom(requested_protocol) and is_function(normalize_fn, 1) do
    {parse_fn, additional_parse_fns} = Keyword.pop(parse_fns, requested_protocol)

    initial_response =
      http_response
      |> parse_fn.()
      |> normalize_fn.()

    with {:error, %UnexpectedResponseError{}} <- initial_response do
      Enum.reduce_while(additional_parse_fns, initial_response, fn {protocol, parse_fn}, acc ->
        http_response
        |> parse_fn.()
        |> normalize_fn.()
        |> case do
          {:error, %UnexpectedResponseError{}} ->
            {:cont, acc}

          response ->
            {:halt,
             {:error,
              ProtocolMismatchError.exception(
                expected_protocol: requested_protocol,
                actual_protocol: protocol,
                response: response
              )}}
        end
      end)
    end
  end

  defp default_normalize_response(response)
  defp default_normalize_response({:error, error}), do: {:error, to_error(error)}
  defp default_normalize_response({:ok, result}), do: {:ok, result}
  defp default_normalize_response(:ok), do: :ok
end
