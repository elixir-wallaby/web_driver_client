defmodule WebDriverClient.JSONWireProtocolClient.ErrorScenarios.ErrorScenario do
  @moduledoc false
  defstruct [:communication_error, :http_status_code, :content_type, :response_body]

  @type http_status_code :: non_neg_integer()

  @type t :: %__MODULE__{
          communication_error: nil | :server_down | :nonexistent_domain,
          http_status_code: http_status_code,
          content_type: String.t() | nil,
          response_body: {:valid_json, map()} | {:other, String.t()}
        }
end
