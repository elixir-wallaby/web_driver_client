# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.JSONWireProtocolClient.Size do
  prerelease_moduledoc """
  A width and height combination
  """

  defstruct [:width, :height]

  @type t :: %__MODULE__{
          height: non_neg_integer,
          width: non_neg_integer
        }
end
