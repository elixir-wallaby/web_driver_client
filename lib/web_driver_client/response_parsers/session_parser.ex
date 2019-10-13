defmodule WebDriverClient.ResponseParsers.SessionParser do
  @moduledoc false

  import WebDriverClient.Guards

  alias WebDriverClient.Session

  @spec parse(term) :: {:ok, Session.t()} | :error
  def parse(%{"value" => %{"sessionId" => session_id}}) when is_session_id(session_id) do
    {:ok, %Session{id: session_id}}
  end

  def parse(%{"sessionId" => session_id}) when is_session_id(session_id) do
    {:ok, %Session{id: session_id}}
  end

  def parse(_), do: :error
end
