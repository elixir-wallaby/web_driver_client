defmodule WebDriverClient.Responses.GenericResponse do
  @moduledoc false

  @type t :: %__MODULE__{
          session_id: String.t() | nil,
          status: integer | nil,
          value: term
        }

  defstruct [:session_id, :status, :value]
end
