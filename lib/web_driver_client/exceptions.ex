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

defmodule WebDriverClient.UnexpectedResponseFormatError do
  @moduledoc """
  Indicates the response we received was in an unexpected format
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

    message = "unexpected format for api response"

    %__MODULE__{response_body: response_body, message: message, reason: reason}
  end
end

defmodule WebDriverClient.UnexpectedStatusCodeError do
  @moduledoc """
  Indicates we received a response with an unexpected HTTP
  status code.
  """

  defexception [:message, :status_code, :response_body]

  @type t :: %__MODULE__{
          message: String.t(),
          status_code: 100..599,
          response_body: String.t()
        }

  def exception(opts) when is_list(opts) do
    status_code = Keyword.fetch!(opts, :status_code)
    response_body = Keyword.fetch!(opts, :response_body)

    message = """
    unexpected HTTP status code
    status_code: #{status_code}"
    response_body: #{inspect(response_body)}"
    """

    %__MODULE__{
      status_code: status_code,
      response_body: response_body,
      message: message
    }
  end
end
