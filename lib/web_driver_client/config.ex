defmodule WebDriverClient.Config do
  @moduledoc """
  Configuration for the webdriver connection
  """

  defstruct [:base_url, :protocol, :debug?]

  @type protocol :: :jwp | :w3c

  @type t :: %__MODULE__{
          base_url: String.t(),
          protocol: protocol,
          debug?: boolean
        }

  @type build_opt :: {:protocol, protocol} | {:debug, boolean}

  @default_protocol :w3c
  @protocols [:jwp, :w3c]

  @doc """
  Builds a new `#{__MODULE__}` struct.
  """
  @spec build(String.t(), [build_opt]) :: t
  def build(base_url, opts \\ []) when is_binary(base_url) and is_list(opts) do
    protocol = Keyword.get(opts, :protocol, @default_protocol)
    debug = Keyword.get(opts, :debug, false)
    %__MODULE__{base_url: base_url, protocol: protocol, debug?: debug}
  end

  @doc """
  Sets the protocol
  """
  @spec put_protocol(t, protocol) :: t
  def put_protocol(%__MODULE__{} = config, protocol) when protocol in @protocols do
    %__MODULE__{config | protocol: protocol}
  end
end
