defmodule WebDriverClient.JSONWireProtocolClient.Response do
  @moduledoc false

  defstruct [:session_id, :status, :value, :original_body]

  @type session_id :: String.t()
  @type status :: non_neg_integer()

  @type t :: %__MODULE__{
          session_id: session_id | nil,
          status: status,
          value: term,
          original_body: map
        }
end
