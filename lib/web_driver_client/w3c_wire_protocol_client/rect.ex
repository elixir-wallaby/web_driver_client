defmodule WebDriverClient.W3CWireProtocolClient.Rect do
  @moduledoc """
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
