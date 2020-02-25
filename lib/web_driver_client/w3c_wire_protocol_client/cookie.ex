# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.W3CWireProtocolClient.Cookie do
  prerelease_moduledoc """
  Details about a cookie stored in the browser
  """

  @type name :: String.t()
  @type value :: String.t()
  @type domain :: String.t()

  @type t :: %__MODULE__{
          name: name,
          value: value,
          domain: domain
        }

  defstruct [:name, :value, :domain]
end
