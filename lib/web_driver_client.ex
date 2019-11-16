defmodule WebDriverClient do
  @moduledoc """
  Webdriver API client.
  """

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.ResponseParsers.FetchSessionsResponseParser
  alias WebDriverClient.ResponseParsers.SessionParser
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError
  alias WebDriverClient.W3CWireProtocolClient

  @type config_opt :: {:config, Config.t()}
  @type url :: String.t()
  @type basic_reason ::
          HTTPClientError.t()
          | UnexpectedResponseFormatError.t()
          | UnexpectedStatusCodeError.t()

  @doc """
  Starts a new session
  """
  @spec start_session(map(), [config_opt]) :: {:ok, Session.t()} | {:error, basic_reason}
  def start_session(payload, opts) when is_list(opts) and is_map(payload) do
    config = Keyword.fetch!(opts, :config)
    client = TeslaClientBuilder.build(config)

    with {:ok, %Env{body: body}} <- Tesla.post(client, "/session", payload) do
      case SessionParser.parse(body, config) do
        {:ok, session} ->
          {:ok, session}

        :error ->
          {:error, UnexpectedResponseFormatError.exception(response_body: body)}
      end
    end
  end

  @doc """
  Returns the list of sessions
  """
  @spec fetch_sessions([config_opt]) :: {:ok, [Session.t()]} | {:error, basic_reason}
  def fetch_sessions(opts) when is_list(opts) do
    config = Keyword.fetch!(opts, :config)
    client = TeslaClientBuilder.build(config)

    with {:ok, %Env{body: body}} <- Tesla.get(client, "/sessions") do
      case FetchSessionsResponseParser.parse(body, config) do
        {:ok, sessions} ->
          {:ok, sessions}

        :error ->
          {:error, UnexpectedResponseFormatError.exception(response_body: body)}
      end
    end
  end

  @doc """
  Ends a session
  """
  @spec end_session(Session.t()) :: :ok | {:error, basic_reason}
  def end_session(%Session{id: id, config: %Config{} = config})
      when is_session_id(id) do
    config
    |> TeslaClientBuilder.build()
    |> Tesla.delete("/session/#{id}")
    |> case do
      {:ok, %Env{}} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Navigates the browser to the given url
  """
  @doc subject: :navigation
  @spec navigate_to(Session.t(), url) :: :ok | {:error, basic_reason}
  def navigate_to(%Session{id: id, config: %Config{} = config}, url)
      when is_session_id(id) and is_url(url) do
    request_body = %{"url" => url}

    config
    |> TeslaClientBuilder.build()
    |> Tesla.post("/session/#{id}/url", request_body)
    |> case do
      {:ok, %Env{}} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns the web browsers current url
  """
  @doc subject: :navigation
  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, basic_reason}
  def fetch_current_url(%Session{config: %Config{protocol: :jwp}} = session) do
    JSONWireProtocolClient.fetch_current_url(session)
  end

  def fetch_current_url(%Session{config: %Config{protocol: :w3c}} = session) do
    W3CWireProtocolClient.fetch_current_url(session)
  end

  @doc """
  Returns the size of the current window
  """
  @spec fetch_window_size(Session.t()) :: {:ok, Size.t()} | {:error, basic_reason}
  def fetch_window_size(%Session{config: %Config{protocol: :jwp}} = session) do
    JSONWireProtocolClient.fetch_window_size(session)
  end

  def fetch_window_size(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.fetch_window_rect(session) do
      {:ok, %W3CWireProtocolClient.Rect{width: width, height: height}} ->
        {:ok, %Size{width: width, height: height}}

      {:error, error} ->
        {:error, error}
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
    JSONWireProtocolClient.set_window_size(session, opts)
  end

  def set_window_size(%Session{config: %Config{protocol: :w3c}} = session, opts)
      when is_list(opts) do
    W3CWireProtocolClient.set_window_rect(session, opts)
  end

  @doc """
  Fetches the log types from the server
  """
  @doc subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [String.t()]} | {:error, basic_reason()}
  def fetch_log_types(%Session{config: %Config{protocol: :jwp}} = session) do
    JSONWireProtocolClient.fetch_log_types(session)
  end

  def fetch_log_types(%Session{config: %Config{protocol: :w3c}} = session) do
    W3CWireProtocolClient.fetch_log_types(session)
  end
end
