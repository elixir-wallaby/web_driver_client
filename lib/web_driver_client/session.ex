defmodule WebDriverClient.Session do
  @moduledoc """
  A WebDriver session
  """

  import WebDriverClient.Guards

  alias WebDriverClient.Config

  defstruct [:id, :config]

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          config: Config.t()
        }

  @doc """
  Builds a Session struct.

  This function is usually not called directly. Instead
  sessions are returned by `WebDriverClient.start_session/2`
  or `WebDriverClient.fetch_sessions/1`.
  """
  @spec build(id, Config.t()) :: t
  def build(id, %Config{} = config) when is_session_id(id) do
    %__MODULE__{id: id, config: config}
  end
end
