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
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.Session
  alias WebDriverClient.Size

  @type url :: String.t()

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
end
