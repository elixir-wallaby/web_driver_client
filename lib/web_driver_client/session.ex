defmodule WebDriverClient.Session do
  @moduledoc """
  A WebDriver session
  """

  defstruct [:id]

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id
        }
end
