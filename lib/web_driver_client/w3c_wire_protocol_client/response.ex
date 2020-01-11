defmodule WebDriverClient.W3CWireProtocolClient.Response do
  @moduledoc false

  alias WebDriverClient.HTTPResponse

  defstruct [:body, :http_response]

  @type t :: %__MODULE__{
          body: term,
          http_response: HTTPResponse.t()
        }
end
