defmodule WebDriverClient.HTTPClientError do
  @moduledoc """
  Indicates the request was unable to be completed due to a low level
  HTTP client error.
  """
  defexception [:message, :reason]

  @type t :: %__MODULE__{
          message: String.t(),
          reason: atom
        }

  def exception(opts) when is_list(opts) do
    reason = Keyword.fetch!(opts, :reason)
    message = "unable to complete HTTP request: #{inspect(reason)}"

    %__MODULE__{reason: reason, message: message}
  end
end

defmodule WebDriverClient.UnexpectedResponseError do
  @moduledoc """
  Indicates an unexpected response was returned from the
  server
  """

  alias WebDriverClient.Config

  defexception [:message, :response_body, :reason, :protocol]

  @type t :: %__MODULE__{
          message: String.t(),
          response_body: term,
          reason: term,
          protocol: Config.protocol()
        }

  def exception(opts) when is_list(opts) do
    response_body = Keyword.get(opts, :response_body)
    reason = Keyword.get(opts, :reason)
    protocol = Keyword.fetch!(opts, :protocol)

    message = "unexpected response"

    %__MODULE__{
      response_body: response_body,
      message: message,
      reason: reason,
      protocol: protocol
    }
  end
end

defmodule WebDriverClient.WebDriverError do
  @moduledoc """
  Indicates a known WebDriver error occurred
  """

  defexception [:message, :reason]

  @type reason :: :invalid_selector
  @type t :: %__MODULE__{
          message: String.t(),
          reason: reason
        }

  def exception(opts) do
    reason = Keyword.fetch!(opts, :reason)

    message = """
    a WebDriver error occurred: #{inspect(reason)}
    """

    %__MODULE__{message: message, reason: reason}
  end
end
