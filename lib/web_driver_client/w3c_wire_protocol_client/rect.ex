# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
import WebDriverClient.CompatibilityMacros

defmodule WebDriverClient.W3CWireProtocolClient.Rect do
  prerelease_moduledoc """
  A window's rectangle
  """

  defstruct [:x, :y, :width, :height]

  @type t :: %__MODULE__{
          x: integer,
          y: integer,
          width: non_neg_integer,
          height: non_neg_integer
        }
end
