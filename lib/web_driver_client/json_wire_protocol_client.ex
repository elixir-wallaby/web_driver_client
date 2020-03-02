# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.JSONWireProtocolClient do
  prerelease_moduledoc """
  Low-level client for JSON wire protocol (JWP).

  Use `WebDriverClient` if you'd like to support both JWP
  and W3C protocols without changing code. This module is only
  intended for use if you need JWP specific functionality.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
  """

  import WebDriverClient.JSONWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.ConnectionError
  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient.Commands
  alias WebDriverClient.JSONWireProtocolClient.Cookie
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.ServerStatus
  alias WebDriverClient.JSONWireProtocolClient.Size
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.KeyCodes
  alias WebDriverClient.Session

  @type url :: String.t()
  @type attribute_name :: String.t()

  @type basic_reason ::
          ConnectionError.t()
          | UnexpectedResponseError.t()
          | WebDriverError.t()

  @doc """
  Starts a new session

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-session
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

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessions
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

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#delete-sessionsessionid
  """
  doc_metadata subject: :sessions
  @spec end_session(Session.t()) :: :ok | {:error, basic_reason}
  def end_session(%Session{id: id} = session)
      when is_session_id(id) do
    with {:ok, http_response} <- Commands.EndSession.send_request(session),
         :ok <- Commands.EndSession.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Navigate to a new URL

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidurl
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
  Fetches the url of the current page.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidurl
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
  Fetches the title of the current page.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidtitle
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
  Fetches the page source of the current page.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidtitle
  """
  doc_metadata subject: :navigation
  @spec fetch_page_source(Session.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def fetch_page_source(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchPageSource.send_request(session),
         {:ok, page_source} <- Commands.FetchPageSource.parse_response(http_response) do
      {:ok, page_source}
    end
  end

  @spec fetch_window_size(Session.t()) :: {:ok, Size.t()} | {:error, basic_reason}
  def fetch_window_size(%Session{id: id} = session)
      when is_session_id(id) do
    with {:ok, http_response} <- Commands.FetchWindowSize.send_request(session),
         {:ok, size} <- Commands.FetchWindowSize.parse_response(http_response) do
      {:ok, size}
    end
  end

  @type size_opt :: {:width, pos_integer} | {:height, pos_integer}

  @spec set_window_size(Session.t(), [size_opt]) :: :ok | {:error, basic_reason}
  def set_window_size(%Session{} = session, opts \\ [])
      when is_list(opts) do
    with {:ok, http_response} <- Commands.SetWindowSize.send_request(session, opts),
         :ok <- Commands.SetWindowSize.parse_response(http_response) do
      :ok
    end
  end

  @type element_location_strategy :: :css_selector | :xpath
  @type element_selector :: String.t()

  @doc """
  Finds the first element using the given search strategy.

  If no elements are found, a `WebDriverError` is returned.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelement
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
           Commands.FindElement.send_request(session, element_location_strategy, element_selector),
         {:ok, element} <- Commands.FindElement.parse_response(http_response) do
      {:ok, element}
    end
  end

  @doc """
  Finds the elements using the given search strategy

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelements
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
  Finds elements that are children of the given element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidelements
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
  Fetches the currently active (focused) element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementactive
  """
  doc_metadata subject: :elements

  @spec fetch_active_element(Session.t()) :: {:ok, Element.t()} | {:error, basic_reason}
  def fetch_active_element(%Session{} = session) do
    with {:ok, http_response} <- Commands.FetchActiveElement.send_request(session),
         {:ok, element} <- Commands.FetchActiveElement.parse_response(http_response) do
      {:ok, element}
    end
  end

  @type log_type :: String.t()

  @doc """
  Fetches the available log types.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlogtypes
  """
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

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlog
  """
  doc_metadata subject: :logging
  @spec fetch_logs(Session.t(), log_type) :: {:ok, [LogEntry.t()]} | {:error, basic_reason()}
  def fetch_logs(%Session{} = session, log_type) do
    with {:ok, http_response} <- Commands.FetchLogs.send_request(session, log_type),
         {:ok, log_entries} <- Commands.FetchLogs.parse_response(http_response) do
      {:ok, log_entries}
    end
  end

  @doc """
  Sends a request to the server to see if an element
  is displayed

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidelementiddisplayed
  """
  doc_metadata subject: :elements

  @spec fetch_element_displayed(Session.t(), Element.t()) ::
          {:ok, boolean} | {:error, basic_reason}

  def fetch_element_displayed(
        %Session{} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <- Commands.FetchElementDisplayed.send_request(session, element),
         {:ok, boolean} <- Commands.FetchElementDisplayed.parse_response(http_response) do
      {:ok, boolean}
    end
  end

  @doc """
  Fetchs the attribute value of an element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidelementidattributename
  """
  doc_metadata subject: :elements

  @spec fetch_element_attribute(Session.t(), Element.t(), attribute_name) ::
          {:ok, String.t()} | {:error, basic_reason}

  def fetch_element_attribute(
        %Session{} = session,
        %Element{} = element,
        attribute_name
      )
      when is_attribute_name(attribute_name) do
    with {:ok, http_response} <-
           Commands.FetchElementAttribute.send_request(session, element, attribute_name),
         {:ok, boolean} <- Commands.FetchElementAttribute.parse_response(http_response) do
      {:ok, boolean}
    end
  end

  @doc """
  Fetchess the visible text of an element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidelementidtext
  """
  doc_metadata subject: :elements

  @spec fetch_element_text(Session.t(), Element.t()) :: {:ok, String.t()} | {:error, basic_reason}
  def fetch_element_text(
        %Session{} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <- Commands.FetchElementText.send_request(session, element),
         {:ok, text} <- Commands.FetchElementText.parse_response(http_response) do
      {:ok, text}
    end
  end

  @doc """
  Clicks an element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidclick
  """
  doc_metadata subject: :elements

  @spec click_element(Session.t(), Element.t()) :: :ok | {:error, basic_reason}
  def click_element(
        %Session{} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <- Commands.ClickElement.send_request(session, element),
         :ok <- Commands.ClickElement.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Clear a TEXTAREA or text INPUT element's value.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidclear
  """
  doc_metadata subject: :elements

  @spec clear_element(Session.t(), Element.t()) :: :ok | {:error, basic_reason}
  def clear_element(
        %Session{} = session,
        %Element{} = element
      ) do
    with {:ok, http_response} <- Commands.ClearElement.send_request(session, element),
         :ok <- Commands.ClearElement.parse_response(http_response) do
      :ok
    end
  end

  @type key_code :: unquote_splicing([KeyCodes.key_code_atoms_union()])
  @type keystroke :: String.t() | key_code
  @type keys :: keystroke | [keystroke]

  @doc """
  Send a sequence of key strokes to an element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidvalue
  """
  doc_metadata subject: :elements
  @spec send_keys_to_element(Session.t(), Element.t(), keys) :: :ok | {:error, basic_reason}
  def send_keys_to_element(%Session{id: id} = session, %Element{} = element, keys)
      when is_session_id(id) do
    with {:ok, http_response} <- Commands.SendKeysToElement.send_request(session, element, keys),
         :ok <- Commands.SendKeysToElement.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Send a sequence of key strokes to the active element

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidkeys
  """
  @spec send_keys(Session.t(), keys) :: :ok | {:error, basic_reason}
  def send_keys(%Session{id: id} = session, keys)
      when is_session_id(id) do
    with {:ok, http_response} <- Commands.SendKeys.send_request(session, keys),
         :ok <- Commands.SendKeys.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Fetches the text of the current alert.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidalert_text
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
  Sends keystrokes to a JavaScript `prompt()` dialog.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidalert_text
  """
  doc_metadata subject: :alerts
  @spec send_alert_text(Session.t(), String.t()) :: :ok | {:error, basic_reason}
  def send_alert_text(%Session{id: id} = session, text)
      when is_session_id(id) and is_binary(text) do
    with {:ok, http_response} <- Commands.SendAlertText.send_request(session, text),
         :ok <- Commands.SendAlertText.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Accepts the currently active alert.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidaccept_alert
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
  Dismisses the currently active alert.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessioniddismiss_alert
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

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidscreenshot
  """
  @spec take_screenshot(Session.t()) :: {:ok, binary} | {:error, basic_reason}
  def take_screenshot(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.TakeScreenshot.send_request(session),
         {:ok, image_data} <- Commands.TakeScreenshot.parse_response(http_response) do
      {:ok, image_data}
    end
  end

  @doc """
  Fetches all cookies visible to the current page.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidcookie
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
  Sets a cookie.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidcookie
  """
  @spec set_cookie(Session.t(), Cookie.name(), Cookie.value(), [set_cookie_opt]) ::
          :ok | {:error, basic_reason()}
  def set_cookie(%Session{} = session, name, value, opts \\ [])
      when is_cookie_name(name) and is_cookie_value(value) and is_list(opts) do
    with {:ok, http_response} <- Commands.SetCookie.send_request(session, name, value, opts),
         :ok <- Commands.SetCookie.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Deletes all cookies visible to the current page.

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#delete-sessionsessionidcookie
  """
  @spec delete_cookies(Session.t()) :: :ok | {:error, basic_reason}
  def delete_cookies(%Session{id: id} = session) when is_session_id(id) do
    with {:ok, http_response} <- Commands.DeleteCookies.send_request(session),
         :ok <- Commands.DeleteCookies.parse_response(http_response) do
      :ok
    end
  end

  @doc """
  Fetches the current server status

  Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-status
  """
  @spec fetch_server_status(Config.t()) :: {:ok, ServerStatus.t()} | {:error, basic_reason()}
  def fetch_server_status(%Config{} = config) do
    with {:ok, http_response} <- Commands.FetchServerStatus.send_request(config),
         {:ok, server_status} <- Commands.FetchServerStatus.parse_response(http_response) do
      {:ok, server_status}
    end
  end
end
