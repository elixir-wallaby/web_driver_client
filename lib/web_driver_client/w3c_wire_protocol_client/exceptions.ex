# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError do
  prerelease_moduledoc """
  Indicates an unexpected response was received from
  the server.
  """

  defexception [:message, :response_body, :reason]

  @type t :: %__MODULE__{
          message: String.t(),
          response_body: term,
          reason: term
        }

  def exception(opts) when is_list(opts) do
    response_body = Keyword.fetch!(opts, :response_body)
    reason = Keyword.get(opts, :reason)

    message = "unexpected response"

    %__MODULE__{response_body: response_body, message: message, reason: reason}
  end
end

defmodule WebDriverClient.W3CWireProtocolClient.WebDriverError do
  prerelease_moduledoc """
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
