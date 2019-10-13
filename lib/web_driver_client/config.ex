defmodule WebDriverClient.Config do
  @moduledoc """
  Configuration for the webdriver connection
  """

  defstruct [:base_url]

  @type t :: %__MODULE__{
          base_url: String.t()
        }

  @type build_opt :: {:base_url, String.t()}

  @doc """
  Builds a new `#{__MODULE__}` struct.
  """
  @spec build([build_opt]) :: t
  def build(opts) when is_list(opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    %__MODULE__{base_url: base_url}
  end
end
