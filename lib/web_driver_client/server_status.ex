defmodule WebDriverClient.ServerStatus do
  @moduledoc """
  A server status response
  """

  @type t :: %__MODULE__{
          ready?: boolean
        }

  defstruct [:ready?]
end
