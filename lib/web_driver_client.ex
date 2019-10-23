defmodule WebDriverClient do
  @moduledoc """
  Webdriver API client.
  """

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.ResponseParsers.FetchSessionsResponseParser
  alias WebDriverClient.ResponseParsers.GenericResponseParser
  alias WebDriverClient.ResponseParsers.SessionParser
  alias WebDriverClient.Responses.GenericResponse
  alias WebDriverClient.Session
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError

  @type config_opt :: {:config, Config.t()}
  @type url :: String.t()

  @doc """
  Starts a new session
  """
  @spec start_session(map(), [config_opt]) ::
          {:ok, Session.t()}
          | {:error,
             HTTPClientError.t()
             | UnexpectedResponseFormatError.t()
             | UnexpectedStatusCodeError.t()}
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
  @spec fetch_sessions([config_opt]) ::
          {:ok, [Session.t()]}
          | {:error,
             HTTPClientError.t()
             | UnexpectedResponseFormatError.t()
             | UnexpectedStatusCodeError.t()}
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
  @spec end_session(Session.t()) ::
          :ok | {:error, HTTPClientError.t() | UnexpectedStatusCodeError.t()}

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
  @spec navigate_to(Session.t(), url) ::
          :ok | {:error, HTTPClientError.t() | UnexpectedStatusCodeError.t()}
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
  @spec fetch_current_url(Session.t()) ::
          {:ok, url} | {:error, HTTPClientError.t() | UnexpectedStatusCodeError.t()}
  def fetch_current_url(%Session{id: id, config: %Config{} = config})
      when is_session_id(id) do
    client = TeslaClientBuilder.build(config)

    with {:ok, %Env{body: body}} <- Tesla.get(client, "/session/#{id}/url") do
      case GenericResponseParser.parse(body) do
        {:ok, %GenericResponse{value: value}} when is_url(value) ->
          {:ok, value}

        :error ->
          {:error, UnexpectedResponseFormatError.exception(response_body: body)}
      end
    end
  end
end
