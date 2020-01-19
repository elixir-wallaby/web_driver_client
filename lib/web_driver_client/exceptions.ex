defmodule WebDriverClient.ConnectionError do
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

defmodule WebDriverClient.ProtocolMismatchError do
  @moduledoc """
  Indicates the server returned a parsable response, but
  not for the requested protocol.
  """

  defexception [:response, :expected_protocol, :actual_protocol]

  @type t :: %{
          response: {:ok, term} | {:error, WebDriverClient.basic_reason()},
          expected_protocol: WebDriverClient.Config.protocol(),
          actual_protocol: WebDriverClient.Config.protocol()
        }

  def exception(opts) when is_list(opts) do
    response = Keyword.fetch!(opts, :response)
    expected_protocol = Keyword.fetch!(opts, :expected_protocol)
    actual_protocol = Keyword.fetch!(opts, :actual_protocol)

    %__MODULE__{
      response: response,
      actual_protocol: actual_protocol,
      expected_protocol: expected_protocol
    }
  end

  def message(error) do
    %__MODULE__{
      expected_protocol: expected_protocol,
      actual_protocol: actual_protocol
    } = error

    """
    protocol of server response did not match expected protocol

        expected_protocol: #{inspect(expected_protocol)}
        actual_protocol: #{inspect(actual_protocol)}

    Please check your server's configuration as this may lead to unexpected behavior.
    """
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
