defmodule WebDriverClient.JSONWireProtocolClient.Response do
  @moduledoc false

  alias WebDriverClient.HTTPResponse

  defstruct [:session_id, :status, :value, :http_response]

  @type session_id :: String.t()
  @type status :: non_neg_integer()

  @type t :: %__MODULE__{
          session_id: session_id | nil,
          status: status,
          value: term,
          http_response: HTTPResponse.t()
        }
end
