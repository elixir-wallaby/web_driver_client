# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.JSONWireProtocolClient.LogEntry do
  prerelease_moduledoc """
  A log entry
  """

  defstruct [:level, :message, :source, :timestamp]

  @type log_level :: String.t()
  @type source :: String.t()
  @type message :: String.t()

  @type t :: %__MODULE__{
          level: log_level,
          message: message,
          source: source | nil,
          timestamp: DateTime.t()
        }
end
