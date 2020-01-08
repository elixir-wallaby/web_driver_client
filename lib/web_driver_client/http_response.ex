defmodule WebDriverClient.HTTPResponse do
  @moduledoc false

  @type status :: non_neg_integer()
  @type body :: binary()
  @type headers :: [{String.t(), String.t()}]

  @type t :: %__MODULE__{
          headers: headers,
          status: status,
          body: body
        }

  defstruct [:status, :body, :headers]
end
