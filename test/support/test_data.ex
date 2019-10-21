defmodule WebDriverClient.TestData do
  @moduledoc """
  StreamData generators used by the project
  """
  use ExUnitProperties

  alias WebDriverClient.Config
  alias WebDriverClient.Session

  @spec session(keyword()) :: StreamData.t(Session.t())
  def session(opts \\ []) when is_list(opts) do
    [
      config: config(),
      id: session_id()
    ]
    |> Keyword.merge(opts)
    |> fixed_map()
    |> map(&struct!(Session, &1))
  end

  @spec config(keyword) :: StreamData.t(Config.t())
  def config(opts \\ []) when is_list(opts) do
    [
      base_url: constant("http://foo")
    ]
    |> Keyword.merge(opts)
    |> fixed_map()
    |> map(&struct!(Config, &1))
  end

  @spec session_id :: StreamData.t(Session.id())
  def session_id do
    string(:alphanumeric, length: 20)
  end
end
