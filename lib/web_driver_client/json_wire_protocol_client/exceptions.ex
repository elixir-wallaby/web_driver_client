defmodule WebDriverClient.JSONWireProtocolClient.UnexpectedResponseError do
  @moduledoc """
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
    response_body = Keyword.get(opts, :response_body)
    reason = Keyword.get(opts, :reason)

    message = "unexpected response"

    %__MODULE__{response_body: response_body, message: message, reason: reason}
  end
end

defmodule WebDriverClient.JSONWireProtocolClient.WebDriverError do
  @moduledoc """
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
