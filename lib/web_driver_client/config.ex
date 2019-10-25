defmodule WebDriverClient.Config do
  @moduledoc """
  Configuration for the webdriver connection
  """

  defstruct [:base_url, :protocol]

  @type protocol :: :jwp | :w3c

  @type t :: %__MODULE__{
          base_url: String.t(),
          protocol: protocol
        }

  @type build_opt :: {:base_url, String.t()} | {:protocol, protocol}

  @default_protocol :w3c

  @doc """
  Builds a new `#{__MODULE__}` struct.
  """
  @spec build([build_opt]) :: t
  def build(opts) when is_list(opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    protocol = Keyword.get(opts, :protocol, @default_protocol)
    %__MODULE__{base_url: base_url, protocol: protocol}
  end
end
