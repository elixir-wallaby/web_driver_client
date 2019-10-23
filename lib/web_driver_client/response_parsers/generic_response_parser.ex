defmodule WebDriverClient.ResponseParsers.GenericResponseParser do
  @moduledoc false

  import WebDriverClient.Guards

  alias WebDriverClient.Responses.GenericResponse

  defguardp is_status(term) when is_integer(term)

  @spec parse(term) :: {:ok, GenericResponse.t()} | :error
  def parse(%{"sessionId" => session_id, "value" => value, "status" => status})
      when is_session_id(session_id) and is_status(status) do
    {:ok, %GenericResponse{session_id: session_id, status: status, value: value}}
  end

  def parse(%{"value" => value}) do
    {:ok, %GenericResponse{value: value}}
  end

  def parse(_), do: :error
end
