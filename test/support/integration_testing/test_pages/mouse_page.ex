defmodule WebDriverClient.IntegrationTesting.TestPages.MousePage do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.TestPages.Server

  defmodule Rect do
    @moduledoc false
    defstruct [:x, :y, :width, :height]
  end

  @spec url :: String.t()
  def url do
    Path.join([Server.get_base_url(), "mouse.html"])
  end

  @spec css_selector_for_hoverable_element :: String.t()
  def css_selector_for_hoverable_element do
    "#hoverable-element"
  end

  @spec hoverable_element_rect :: Rect.t()
  def hoverable_element_rect do
    %Rect{x: 50, y: 100, width: 125, height: 175}
  end
end
