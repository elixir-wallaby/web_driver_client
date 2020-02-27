# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.W3CWireProtocolClient do
  prerelease_moduledoc """
  Low-level client for W3C wire protocol.

  Use `WebDriverClient` if you'd like to support both JWP
  and W3C protocols without changing code. This module is only
  intended for use if you need W3C specific functionality.

  Specification: https://w3c.github.io/webdriver/
  """

  import WebDriverClient.W3CWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.Element
  alias WebDriverClient.KeyCodes
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient.Commands
  alias WebDriverClient.W3CWireProtocolClient.Cookie
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.ServerStatus
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @type url :: String.t()
  @type attribute_name :: String.t()
  @type property_name :: String.t()

  @type basic_reason ::
          ConnectionError.t()
          | UnexpectedResponseError.t()
          | WebDriverError.t()

  @doc """
  Starts a new session

  Specification: https://w3c.github.io/webdriver/#new-session-0
  """
  doc_metadata subject: :sessions
  @spec start_session(map, Config.t()) :: {:ok, Session.t()} | {:error, basic_reason}
  def start_session(payload, %Config{} = config) when is_map(payload) do
    with {:ok, http_response} <- Commands.StartSession.send_request(config, payload),
         {:ok, session} <- Commands.StartSession.parse_response(http_response, config) do
      {:ok, session}
    end
  end

  @doc """
  Returns the list of currently active sessions

  This isn't part of the official W3C spec
  """
  doc_metadata subject: :sessions
  @spec fetch_sessions(Config.t()) :: {:ok, [Session.t()]} | {:error, basic_reason}
  def fetch_sessions(%Config{} = config) do
    with {:ok, http_response} <- Commands.FetchSessions.send_request(config),
         {:ok, sessions} <- Commands.FetchSessions.parse_response(http_response, config) do
      {:ok, sessions}
    end
  end

  @doc """
  End the session.

  Specification: https://w3c.github.io/webdriver/#delete-session
  """
  doc_metadata subject: :sessions
  @spec end_session(Session.t()) :: :ok | {:error, basic_reason}
  def end_session(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.EndSession.send_request(session),
         :ok <- Commands.EndSession.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Navigate to a new URL

  Specification: https://w3c.github.io/webdriver/#navigate-to
  """
  doc_metadata subject: :navigation
  @spec navigate_to(Session.t(), url) :: :ok | {:error, basic_reason}
  def navigate_to(%Session{} = session, url) when is_url(url) do
    with {:ok, http_response} <- Commands.NavigateTo.send_request(session, url),
         :ok <- Commands.NavigateTo.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Fetches the current url of the top-level browsing context.

  Specification: https://w3c.github.io/webdriver/#get-current-url
  """
  doc_metadata subject: :navigation
  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, basic_reason}
  def fetch_current_url(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchCurrentURL.send_request(session),
         {:ok, url} <- Commands.FetchCurrentURL.parse_response(http_response) do
      {:ok, url}
    end
  end

  @doc """
  Fetches the document title of the top-level browsing context.

  Specification: https://w3c.github.io/webdriver/#get-title
  """
  doc_metadata subject: :navigation
  @spec fetch_title(Session.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def fetch_title(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchTitle.send_request(session),
         {:ok, title} <- Commands.FetchTitle.parse_response(http_response) do
      {:ok, title}
    end
  end

  @doc """
  Fetches the page source of the top-level browsing context.

  Specification: https://w3c.github.io/webdriver/#get-page-source
  """
  doc_metadata subject: :navigation
  @spec fetch_page_source(Session.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def fetch_page_source(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchPageSource.send_request(session),
         {:ok, page_source} <- Commands.FetchPageSource.parse_response(http_response) do
      {:ok, page_source}
    end
  end

  @spec fetch_window_rect(Session.t()) :: {:ok, Rect.t()} | {:error, basic_reason}
  def fetch_window_rect(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchWindowRect.send_request(session),
         {:ok, url} <- Commands.FetchWindowRect.parse_response(http_response) do
      {:ok, url}
    end
  end

  @type rect_opt :: {:width, pos_integer} | {:height, pos_integer} | {:x, integer} | {:y, integer}

  @spec set_window_rect(Session.t(), [rect_opt]) :: :ok | {:error, basic_reason}
  def set_window_rect(%Session{} = session, opts \\ [])
      when is_list(opts) do
    with {:ok, http_response} <- Commands.SetWindowRect.send_request(session, opts),
         :ok <- Commands.SetWindowRect.parse_response(http_response) do
      :ok
    end
  end

  @type log_type :: String.t()

  doc_metadata subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [log_type]} | {:error, basic_reason()}
  def fetch_log_types(%Session{} = session) do
    with {:ok, http_response} <- Commands.FetchLogTypes.send_request(session),
         {:ok, log_types} <- Commands.FetchLogTypes.parse_response(http_response) do
      {:ok, log_types}
    end
  end

  @doc """
  Fetches the log for a given type.

  This function is not part of the official spec and is
  not supported by all servers.
  """
  doc_metadata subject: :logging
  @spec fetch_logs(Session.t(), log_type) :: {:ok, [LogEntry.t()]} | {:error, basic_reason()}
  def fetch_logs(%Session{} = session, log_type) do
    with {:ok, http_response} <- Commands.FetchLogs.send_request(session, log_type),
         {:ok, log_entries} <- Commands.FetchLogs.parse_response(http_response) do
      {:ok, log_entries}
    end
  end

  @type element_location_strategy :: :css_selector | :xpath
  @type element_selector :: String.t()

  @doc """
  Finds the first element using the given search strategy.

  If no elements are found, a `WebDriverError` is returned.

  Specification: https://w3c.github.io/webdriver/#find-element
  """
  doc_metadata subject: :elements

  @spec find_element(Session.t(), element_location_strategy, element_selector) ::
          {:ok, Element.t()} | {:error, basic_reason}
  def find_element(
        %Session{} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    with {:ok, http_response} <-
           Commands.FindElement.send_request(
             session,
             element_location_strategy,
             element_selector
           ),
         {:ok, element} <- Commands.FindElement.parse_response(http_response) do
      {:ok, element}
    end
  end

  @doc """
  Finds the elements using the given search strategy

  Specification: https://w3c.github.io/webdriver/#find-elements
  """
  doc_metadata subject: :elements

  @spec find_elements(Session.t(), element_location_strategy, element_selector) ::
          {:ok, [Element.t()]} | {:error, basic_reason}
  def find_elements(
        %Session{} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    with {:ok, http_response} <-
           Commands.FindElements.send_request(
             session,
             element_location_strategy,
             element_selector
           ),
         {:ok, elements} <- Commands.FindElements.parse_response(http_response) do
      {:ok, elements}
    end
  end

  @doc """
  Finds the elements that are children of the given element

  Specification: https://w3c.github.io/webdriver/#find-elements-from-element
  """
  doc_metadata subject: :elements

  @spec find_elements_from_element(
          Session.t(),
          Element.t(),
          element_location_strategy,
          element_selector
        ) :: {:ok, [Element.t()]} | {:error, basic_reason}
  def find_elements_from_element(
        %Session{} = session,
        %Element{} = element,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    with {:ok, http_response} <-
           Commands.FindElementsFromElement.send_request(
             session,
             element,
             element_location_strategy,
             element_selector
           ),
         {:ok, elements} <- Commands.FindElementsFromElement.parse_response(http_response) do
      {:ok, elements}
    end
  end

  @doc """
  Fetches the currently active element

  Specification: https://w3c.github.io/webdriver/#get-active-element
  """
  doc_metadata subject: :elements

  @spec fetch_active_element(Session.t()) :: {:ok, Element.t()} | {:error, basic_reason}
  def fetch_active_element(%Session{} = session) do
    with {:ok, http_response} <- Commands.FetchActiveElement.send_request(session),
         {:ok, element} <- Commands.FetchActiveElement.parse_response(http_response) do
      {:ok, element}
    end
  end

  @doc """
  Sends a request to the server to see if an element
  is displayed

  Specification: https://w3c.github.io/webdriver/#element-displayedness
  """
  doc_metadata subject: :elements

  @spec fetch_element_displayed(Session.t(), Element.t()) ::
          {:ok, boolean} | {:error, basic_reason}

  def fetch_element_displayed(%Session{} = session, %Element{} = element) do
    with {:ok, http_response} <- Commands.FetchElementDisplayed.send_request(session, element),
         {:ok, boolean} <- Commands.FetchElementDisplayed.parse_response(http_response) do
      {:ok, boolean}
    end
  end

  @doc """
  Fetches the value of an element's attribute

  Specification: https://w3c.github.io/webdriver/#get-element-attribute
  """
  doc_metadata subject: :elements

  @spec fetch_element_attribute(Session.t(), Element.t(), attribute_name) ::
          {:ok, String.t()} | {:error, basic_reason}

  def fetch_element_attribute(%Session{} = session, %Element{} = element, attribute_name)
      when is_attribute_name(attribute_name) do
    with {:ok, http_response} <-
           Commands.FetchElementAttribute.send_request(session, element, attribute_name),
         {:ok, value} <- Commands.FetchElementAttribute.parse_response(http_response) do
      {:ok, value}
    end
  end

  @doc """
  Fetches the value of an element's property

  Specification: https://w3c.github.io/webdriver/#get-element-property
  """
  doc_metadata subject: :elements

  @spec fetch_element_property(Session.t(), Element.t(), property_name) ::
          {:ok, String.t()} | {:error, basic_reason}

  def fetch_element_property(%Session{} = session, %Element{} = element, property_name)
      when is_property_name(property_name) do
    with {:ok, http_response} <-
           Commands.FetchElementProperty.send_request(session, element, property_name),
         {:ok, value} <- Commands.FetchElementProperty.parse_response(http_response) do
      {:ok, value}
    end
  end

  @doc """
  Fetches an elements visible text

  Specification: https://w3c.github.io/webdriver/#get-element-text
  """
  doc_metadata subject: :elements

  @spec fetch_element_text(Session.t(), Element.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def fetch_element_text(%Session{} = session, %Element{} = element) do
    with {:ok, http_response} <- Commands.FetchElementText.send_request(session, element),
         {:ok, value} <- Commands.FetchElementText.parse_response(http_response) do
      {:ok, value}
    end
  end

  @doc """
  Clicks an element

  Specification: https://w3c.github.io/webdriver/#element-click
  """
  doc_metadata subject: :elements

  @spec click_element(Session.t(), Element.t()) :: :ok | {:error, basic_reason}
  def click_element(%Session{} = session, %Element{} = element) do
    with {:ok, http_response} <- Commands.ClickElement.send_request(session, element),
         :ok <- Commands.ClickElement.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Clears a resettable or content editable element

  Specification: https://w3c.github.io/webdriver/#element-clear
  """
  doc_metadata subject: :elements

  @spec clear_element(Session.t(), Element.t()) :: :ok | {:error, basic_reason}
  def clear_element(%Session{} = session, %Element{} = element) do
    with {:ok, http_response} <- Commands.ClearElement.send_request(session, element),
         :ok <- Commands.ClearElement.parse_response(http_response) do
      :ok
    end
  end

  @type key_code :: unquote_splicing([KeyCodes.key_code_atoms_union()])
  @type keystroke :: String.t() | key_code
  @type keys :: keystroke | [keystroke]

  @doc """
  Send keystrokes to an element

  Specification: https://w3c.github.io/webdriver/#element-send-keys
  """
  doc_metadata subject: :elements

  @spec send_keys_to_element(Session.t(), Element.t(), keys) :: :ok | {:error, basic_reason}
  def send_keys_to_element(%Session{} = session, %Element{} = element, keys) do
    with {:ok, http_response} <- Commands.SendKeysToElement.send_request(session, element, keys),
         :ok <- Commands.SendKeysToElement.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Fetches the text of the current alert

  Specification: https://w3c.github.io/webdriver/#get-alert-text
  """
  doc_metadata subject: :alerts
  @spec fetch_alert_text(Session.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def fetch_alert_text(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchAlertText.send_request(session),
         {:ok, alert_text} <- Commands.FetchAlertText.parse_response(http_response) do
      {:ok, alert_text}
    end
  end

  @doc """
  Sets the text field of a `window.prompt()` dialog to the given value

  Specification: https://w3c.github.io/webdriver/#send-alert-text
  """
  doc_metadata subject: :alerts
  @spec send_alert_text(Session.t(), String.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def send_alert_text(%Session{id: id} = session, text)
      when is_session_id(id) and is_binary(text) do
    with {:ok, http_response} <- Commands.SendAlertText.send_request(session, text),
         :ok <- Commands.SendAlertText.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Accepts the currently active alert dialog.

  Specification: https://w3c.github.io/webdriver/#accept-alert
  """
  doc_metadata subject: :alerts
  @spec accept_alert(Session.t()) :: :ok | {:error, basic_reason}
  def accept_alert(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.AcceptAlert.send_request(session),
         :ok <- Commands.AcceptAlert.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Dismisses the currently active alert dialog.

  Specification: https://w3c.github.io/webdriver/#dismiss-alert
  """
  doc_metadata subject: :alerts
  @spec dismiss_alert(Session.t()) :: :ok | {:error, basic_reason}
  def dismiss_alert(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.DismissAlert.send_request(session),
         :ok <- Commands.DismissAlert.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Takes a screenshot of the current page

  Specification: https://w3c.github.io/webdriver/#take-screenshot
  """
  @spec take_screenshot(Session.t()) :: {:ok, binary} | {:error, basic_reason}
  def take_screenshot(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.TakeScreenshot.send_request(session),
         {:ok, image_data} <- Commands.TakeScreenshot.parse_response(http_response) do
      {:ok, image_data}
    end
  end

  @doc """
  Fetches the cookies visible to the current page

  Specification: https://w3c.github.io/webdriver/#get-all-cookies
  """
  @spec fetch_cookies(Session.t()) :: {:ok, [Cookie.t()]} | {:error, basic_reason()}
  def fetch_cookies(%Session{} = session) do
    with {:ok, http_response} <- Commands.FetchCookies.send_request(session),
         {:ok, cookies} <- Commands.FetchCookies.parse_response(http_response) do
      {:ok, cookies}
    end
  end

  @type set_cookie_opt :: {:domain, Cookie.domain()}

  @doc """
  Sets a cookie

  Specification: https://w3c.github.io/webdriver/#add-cookie
  """
  @spec set_cookie(Session.t(), Cookie.name(), Cookie.value(), [set_cookie_opt]) ::
          :ok | {:error, basic_reason}
  def set_cookie(%Session{id: id} = session, name, value, opts \\ [])
      when is_session_id(id) and is_cookie_name(name) and is_cookie_value(value) and is_list(opts) do
    with {:ok, http_response} <- Commands.SetCookie.send_request(session, name, value, opts),
         :ok <- Commands.SetCookie.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Deletes all cookies for the current page

  Specification: https://w3c.github.io/webdriver/#delete-all-cookies
  """
  @spec delete_cookies(Session.t()) :: :ok | {:error, basic_reason}
  def delete_cookies(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.DeleteCookies.send_request(session),
         :ok <- Commands.DeleteCookies.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Fetches the server status

  Specification: https://w3c.github.io/webdriver/#status
  """
  @spec fetch_server_status(Config.t()) :: {:ok, ServerStatus.t()} | {:error, basic_reason()}
  def fetch_server_status(%Config{} = config) do
    with {:ok, http_response} <- Commands.FetchServerStatus.send_request(config),
         {:ok, server_status} <- Commands.FetchServerStatus.parse_response(http_response) do
      {:ok, server_status}
    end
  end
end
