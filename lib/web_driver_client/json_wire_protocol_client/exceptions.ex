# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError do
  prerelease_moduledoc """
  Indicates an unexpected response was received from
  the server.
  """

  defexception [:message, :response_body, :http_status_code, :reason]

  @type http_status_code :: non_neg_integer()

  @type t :: %__MODULE__{
          message: String.t(),
          response_body: term,
          http_status_code: http_status_code,
          reason: term
        }

  def exception(opts) when is_list(opts) do
    response_body = Keyword.fetch!(opts, :response_body)
    reason = Keyword.get(opts, :reason)
    http_status_code = Keyword.fetch!(opts, :http_status_code)

    # Temporary workaround until we can update tests to
    # no longer require response_body to be parsed
    response_body =
      with true <- is_binary(response_body),
           {:ok, parsed} <- Jason.decode(response_body) do
        parsed
      else
        _ -> response_body
      end

    message = "unexpected response"

    %__MODULE__{
      response_body: response_body,
      message: message,
      reason: reason,
      http_status_code: http_status_code
    }
  end
end

defmodule WebDriverClient.JSONWireProtocolClient.WebDriverError do
  prerelease_moduledoc """
  Indicates a known WebDriver error was returned from
  the server
  """

  @typedoc """
  JWP status code

  See https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#response-status-codes
  """
  @type reason :: atom
  @type http_status_code :: non_neg_integer()

  defexception [:reason, :http_status_code, :message]

  @type t :: %__MODULE__{
          reason: reason,
          http_status_code: http_status_code,
          message: String.t()
        }

  def exception(opts) do
    reason = Keyword.fetch!(opts, :reason)
    http_status_code = Keyword.fetch!(opts, :http_status_code)

    message = "web driver returned an unsuccessful status code: #{inspect(reason)}"

    %__MODULE__{reason: reason, http_status_code: http_status_code, message: message}
  end
end
