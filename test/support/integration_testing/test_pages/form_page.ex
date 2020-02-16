defmodule WebDriverClient.IntegrationTesting.TestPages.FormPage do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.TestPages.Server

  @spec url :: String.t()
  def url do
    Path.join([Server.get_base_url(), "form.html"])
  end

  @spec css_selector_for_first_name_field :: String.t()
  def css_selector_for_first_name_field do
    "#first-name"
  end

  @spec css_selector_for_last_name_field :: String.t()
  def css_selector_for_last_name_field do
    "#last-name"
  end
end
