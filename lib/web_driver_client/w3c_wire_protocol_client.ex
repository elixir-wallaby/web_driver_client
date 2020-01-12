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
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient.Commands
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @type url :: String.t()

  @type basic_reason ::
          HTTPClientError.t()
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
end
