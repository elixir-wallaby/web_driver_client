defmodule WebDriverClient.Element do
  @moduledoc """
  A HTML Element result found on a web page
  """

  defstruct [:id]

  @type id :: String.t()

  @type t :: %__MODULE__{id: id}
end
