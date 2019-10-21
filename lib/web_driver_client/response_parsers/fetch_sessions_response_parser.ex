defmodule WebDriverClient.ResponseParsers.FetchSessionsResponseParser do
  @moduledoc false

  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Session

  @spec parse(term, Config.t()) :: {:ok, [Session.t()]} | :error
  def parse(%{"value" => value}, %Config{} = config) when is_list(value) do
    value
    |> Enum.reduce_while([], fn session_response, acc ->
      session_response
      |> parse_session(config)
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

  def parse(_, %Config{}), do: :error

  @spec parse_session(term, Config.t()) :: {:ok, Session.t()} | :error
  defp parse_session(%{"id" => id}, %Config{} = config) when is_session_id(id) do
    {:ok, %Session{id: id, config: config}}
  end

  defp parse_session(_, %Config{}), do: :error
end
