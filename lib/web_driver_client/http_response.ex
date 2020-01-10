defmodule WebDriverClient.HTTPResponse do
  @moduledoc false

  alias Tesla.Env

  @type status :: non_neg_integer()
  @type body :: binary()
  @type headers :: [{String.t(), String.t()}]

  @type t :: %__MODULE__{
          headers: headers,
          status: status,
          body: body
        }

  defstruct [:status, :body, :headers]

  @spec build(Env.t()) :: t
  def build(%Env{status: status, body: body, headers: headers}) do
    %__MODULE__{status: status, body: body, headers: headers}
  end
end
