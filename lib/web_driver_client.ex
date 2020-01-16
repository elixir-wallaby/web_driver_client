defmodule WebDriverClient do
  @moduledoc """
  Webdriver API client.
  """

  import WebDriverClient.CompatibilityMacros
  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.JSONWireProtocolClient.Commands, as: JWPCommands
  alias WebDriverClient.LogEntry
  alias WebDriverClient.ProtocolMismatchError
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.Commands, as: W3CCommands
  alias WebDriverClient.WebDriverError

  @type protocol :: Config.protocol()
  @type url :: String.t()
  @type reason :: ProtocolMismatchError.t() | basic_reason
  @type basic_reason ::
          HTTPClientError.t()
          | UnexpectedResponseError.t()
          | WebDriverError.t()

  @doc """
  Starts a new session
  """
  doc_metadata subject: :sessions
  @spec start_session(Config.t(), map()) :: {:ok, Session.t()} | {:error, basic_reason}
  def start_session(%Config{protocol: :jwp} = config, payload) when is_map(payload) do
    case JSONWireProtocolClient.start_session(payload, config) do
      {:ok, session} ->
        {:ok, session}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def start_session(%Config{protocol: :w3c} = config, payload) when is_map(payload) do
    case W3CWireProtocolClient.start_session(payload, config) do
      {:ok, session} ->
        {:ok, session}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Returns the list of sessions
  """
  doc_metadata subject: :sessions
  @spec fetch_sessions(Config.t()) :: {:ok, [Session.t()]} | {:error, basic_reason}
  def fetch_sessions(%Config{protocol: :jwp} = config) do
    case JSONWireProtocolClient.fetch_sessions(config) do
      {:ok, sessions} ->
        {:ok, sessions}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_sessions(%Config{protocol: :w3c} = config) do
    case W3CWireProtocolClient.fetch_sessions(config) do
      {:ok, session} ->
        {:ok, session}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Ends a session
  """
  doc_metadata subject: :sessions
  @spec end_session(Session.t()) :: :ok | {:error, basic_reason}
  def end_session(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.end_session(session) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def end_session(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.end_session(session) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Navigates the browser to the given url
  """
  doc_metadata subject: :navigation
  @spec navigate_to(Session.t(), url) :: :ok | {:error, basic_reason}

  def navigate_to(%Session{config: %Config{protocol: :jwp}} = session, url)
      when is_url(url) do
    case JSONWireProtocolClient.navigate_to(session, url) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def navigate_to(%Session{config: %Config{protocol: :w3c}} = session, url)
      when is_url(url) do
    case W3CWireProtocolClient.navigate_to(session, url) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Returns the web browsers current url
  """
  doc_metadata subject: :navigation
  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, basic_reason}
  def fetch_current_url(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.fetch_current_url(session) do
      {:ok, current_url} ->
        {:ok, current_url}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_current_url(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.fetch_current_url(session) do
      {:ok, current_url} ->
        {:ok, current_url}

      {:error, error} ->
        {:error, to_error(error)}
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
          {:ok, %Size{} = size} ->
            {:ok, size}

          {:ok, %W3CWireProtocolClient.Rect{width: width, height: height}} ->
            {:ok, %Size{width: width, height: height}}

          {:error, error} ->
            {:error, to_error(error)}
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
          {:ok, Element.t()} | {:error, basic_reason}
  def find_element(
        %Session{config: %Config{protocol: :jwp}} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case JSONWireProtocolClient.find_element(
           session,
           element_location_strategy,
           element_selector
         ) do
      {:ok, element} ->
        {:ok, element}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def find_element(
        %Session{config: %Config{protocol: :w3c}} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case W3CWireProtocolClient.find_element(session, element_location_strategy, element_selector) do
      {:ok, element} ->
        {:ok, element}

      {:error, error} ->
        {:error, to_error(error)}
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
        ) :: {:ok, [Element.t()] | {:error, basic_reason}}
  def find_elements_from_element(
        %Session{config: %Config{protocol: :jwp}} = session,
        %Element{} = element,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case JSONWireProtocolClient.find_elements_from_element(
           session,
           element,
           element_location_strategy,
           element_selector
         ) do
      {:ok, elements} ->
        {:ok, elements}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def find_elements_from_element(
        %Session{config: %Config{protocol: :w3c}} = session,
        %Element{} = element,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case W3CWireProtocolClient.find_elements_from_element(
           session,
           element,
           element_location_strategy,
           element_selector
         ) do
      {:ok, elements} ->
        {:ok, elements}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @type size_opt :: {:width, pos_integer} | {:height, pos_integer}

  @doc """
  Sets the size of the window
  """
  @spec set_window_size(Session.t(), [size_opt]) :: :ok | {:error, basic_reason}
  def set_window_size(session, opts \\ [])

  def set_window_size(%Session{config: %Config{protocol: :jwp}} = session, opts)
      when is_list(opts) do
    case JSONWireProtocolClient.set_window_size(session, opts) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def set_window_size(%Session{config: %Config{protocol: :w3c}} = session, opts)
      when is_list(opts) do
    case W3CWireProtocolClient.set_window_rect(session, opts) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @type log_type :: String.t()

  @doc """
  Fetches the log types from the server
  """
  doc_metadata subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [log_type]} | {:error, basic_reason()}
  def fetch_log_types(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.fetch_log_types(session) do
      {:ok, log_types} ->
        {:ok, log_types}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_log_types(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.fetch_log_types(session) do
      {:ok, log_types} ->
        {:ok, log_types}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Fetches log entries for the requested log type.
  """
  doc_metadata subject: :logging
  @spec fetch_logs(Session.t(), log_type) :: {:ok, [LogEntry.t()]} | {:error, basic_reason()}
  def fetch_logs(session, log_type)

  def fetch_logs(%Session{config: %Config{protocol: :jwp}} = session, log_type)
      when is_binary(log_type) do
    case JSONWireProtocolClient.fetch_logs(session, log_type) do
      {:ok, log_entries} ->
        log_entries = Enum.map(log_entries, &to_log_entry/1)
        {:ok, log_entries}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_logs(%Session{config: %Config{protocol: :w3c}} = session, log_type)
      when is_binary(log_type) do
    case W3CWireProtocolClient.fetch_logs(session, log_type) do
      {:ok, log_entries} ->
        log_entries = Enum.map(log_entries, &to_log_entry/1)
        {:ok, log_entries}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Sends a request to the server to see if an element
  is displayed
  """
  doc_metadata subject: :elements

  @spec fetch_element_displayed(Session.t(), Element.t()) ::
          {:ok, boolean} | {:error, basic_reason}
  def fetch_element_displayed(
        %Session{config: %Config{protocol: :jwp}} = session,
        %Element{} = element
      ) do
    case JSONWireProtocolClient.fetch_element_displayed(session, element) do
      {:ok, displayed?} ->
        {:ok, displayed?}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_element_displayed(
        %Session{config: %Config{protocol: :w3c}} = session,
        %Element{} = element
      ) do
    case W3CWireProtocolClient.fetch_element_displayed(session, element) do
      {:ok, displayed?} ->
        {:ok, displayed?}

      {:error, error} ->
        {:error, to_error(error)}
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

  defp to_error(%JSONWireProtocolClient.WebDriverError{reason: reason}) do
    WebDriverError.exception(reason: reason)
  end

  defp to_error(%W3CWireProtocolClient.WebDriverError{reason: reason}) do
    WebDriverError.exception(reason: reason)
  end

  defp to_error(%HTTPClientError{} = error), do: error

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
          {protocol, (() -> {:ok, HTTPResponse.t()} | {:error, HTTPClientError.t()})}
        ]) :: {:ok, HTTPResponse.t()} | {:error, HTTPClientError.t()}
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
end
