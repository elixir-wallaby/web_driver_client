defmodule WebDriverClient.LogEntry do
  @moduledoc """
  A log entry
  """

  defstruct [:level, :source, :message, :timestamp]

  @type log_level :: String.t()
  @type source :: String.t()
  @type message :: String.t()

  @type t :: %__MODULE__{
          level: log_level,
          source: source | nil,
          message: message,
          timestamp: DateTime.t()
        }
end
