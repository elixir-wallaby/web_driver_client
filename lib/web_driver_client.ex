defmodule WebDriverClient do
  @moduledoc """
  Webdriver API client.
  """

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.ResponseParsers.FetchSessionsResponseParser
  alias WebDriverClient.ResponseParsers.SessionParser
  alias WebDriverClient.Session
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError

  @type config_opt :: {:config, Config.t()}

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
end
