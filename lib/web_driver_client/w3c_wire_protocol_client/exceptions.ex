defmodule WebDriverClient.W3CWireProtocolClient.WebDriverError do
  @moduledoc """
  Indicates a known WebDriver error was returned from
  the server
  """

  @typedoc """
  The error reason

  See: https://w3c.github.io/webdriver/#errors
  """
  @type reason :: atom
  @type http_status_code :: non_neg_integer()

  defexception [:reason, :http_status_code, :message, :stacktrace]

  @type t :: %__MODULE__{
          reason: reason,
          http_status_code: http_status_code,
          stacktrace: String.t(),
          message: String.t()
        }

  def exception(opts) do
    reason = Keyword.fetch!(opts, :reason)
    http_status_code = Keyword.fetch!(opts, :http_status_code)

    stacktrace = Keyword.fetch!(opts, :stacktrace)
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{
      reason: reason,
      http_status_code: http_status_code,
      message: message,
      stacktrace: stacktrace
    }
  end
end
