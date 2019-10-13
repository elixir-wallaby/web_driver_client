defmodule WebDriverClient.ResponseParsers.FetchSessionsResponseParser do
  @moduledoc false

  import WebDriverClient.Guards

  alias WebDriverClient.Session

  @spec parse(term) :: {:ok, [Session.t()]} | :error
  def parse(%{"value" => value}) when is_list(value) do
    value
    |> Enum.reduce_while([], fn session_response, acc ->
      session_response
      |> parse_session()
      |> case do
        {:ok, session} ->
          {:cont, [session | acc]}

        :error ->
          {:halt, :error}
      end
    end)
    |> case do
      sessions when is_list(sessions) ->
        {:ok, Enum.reverse(sessions)}

      :error ->
        :error
    end
  end

  def parse(_), do: :error

  @spec parse_session(any) :: {:ok, Session.t()} | :error
  defp parse_session(%{"id" => id}) when is_session_id(id) do
    {:ok, %Session{id: id}}
  end

  defp parse_session(_), do: :error
end
