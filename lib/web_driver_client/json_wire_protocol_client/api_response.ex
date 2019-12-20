defmodule WebDriverClient.JSONWireProtocolClient.APIResponse do
  @moduledoc false

  defstruct [:session_id, :status, :value]

  @type session_id :: String.t()
  @type status :: non_neg_integer()

  @type t :: %__MODULE__{
          session_id: session_id,
          status: status,
          value: term
        }
end
