defmodule WebDriverClient.IntegrationTesting.TestPages.ElementsPage do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.TestPages.Server

  @spec url :: String.t()
  def url do
    Path.join([Server.get_base_url(), "elements.html"])
  end

  @spec css_selector_for_singular_element :: String.t()
  def css_selector_for_singular_element do
    "h1.page-heading"
  end

  @spec css_selector_for_non_existent_element :: String.t()
  def css_selector_for_non_existent_element do
    "does not exist"
  end
end
