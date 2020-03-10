defmodule WebDriverClient.Config do
  @moduledoc """
  Configuration for the webdriver connection
  """

  defstruct [:base_url, :protocol, :debug?, :http_client_options]

  @type protocol :: :jwp | :w3c

  @type t :: %__MODULE__{
          base_url: String.t(),
          protocol: protocol,
          debug?: boolean,
          http_client_options: list()
        }

  @type build_opt :: {:protocol, protocol} | {:debug, boolean} | {:http_client_options, list}

  @default_protocol :w3c
  @protocols [:jwp, :w3c]

  @doc """
  Builds a new `#{__MODULE__}` struct.
  """
  @spec build(String.t(), [build_opt]) :: t
  def build(base_url, opts \\ []) when is_binary(base_url) and is_list(opts) do
    protocol = Keyword.get(opts, :protocol, @default_protocol)
    debug = Keyword.get(opts, :debug, false)
    http_client_options = Keyword.get(opts, :http_client_options, [])

    %__MODULE__{
      base_url: base_url,
      protocol: protocol,
      debug?: debug,
      http_client_options: http_client_options
    }
  end

  @doc """
  Sets the protocol
  """
  @spec put_protocol(t, protocol) :: t
  def put_protocol(%__MODULE__{} = config, protocol) when protocol in @protocols do
    %__MODULE__{config | protocol: protocol}
  end
end
