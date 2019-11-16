defmodule WebDriverClient.W3CWireProtocolClient.LogEntry do
  @moduledoc """
  A log entry
  """

  defstruct [:level, :message, :timestamp]

  @type log_level :: String.t()
  @type message :: String.t()

  @type t :: %__MODULE__{
          level: log_level,
          message: message,
          timestamp: DateTime.t()
        }
end
