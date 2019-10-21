defmodule WebDriverClient.ResponseParsers.SessionParser do
  @moduledoc false

  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Session

  @spec parse(term, Config.t()) :: {:ok, Session.t()} | :error
  def parse(%{"value" => %{"sessionId" => session_id}}, %Config{} = config)
      when is_session_id(session_id) do
    {:ok, Session.build(session_id, config)}
  end

  def parse(%{"sessionId" => session_id}, %Config{} = config) when is_session_id(session_id) do
    {:ok, Session.build(session_id, config)}
  end

  def parse(_, %Config{}), do: :error
end
