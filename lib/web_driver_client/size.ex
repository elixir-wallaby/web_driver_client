defmodule WebDriverClient.Size do
  @moduledoc """
  A width and height combination
  """

  defstruct [:width, :height]

  @type t :: %__MODULE__{
          height: non_neg_integer,
          width: non_neg_integer
        }
end
