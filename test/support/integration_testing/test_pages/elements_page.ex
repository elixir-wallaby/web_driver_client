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

  @spec css_selector_for_non_visible_element :: String.t()
  def css_selector_for_non_visible_element do
    "#hidden-element"
  end

  @spec css_selector_for_sample_list :: String.t()
  def css_selector_for_sample_list do
    "ul#sample-list"
  end

  @spec xpath_selector_for_list_items :: String.t()
  def xpath_selector_for_list_items do
    "//ul[@id='sample-list']/li"
  end

  @spec text_input_id :: String.t()
  def text_input_id do
    "text-input"
  end

  @spec css_selector_for_text_input :: String.t()
  def css_selector_for_text_input do
    "#" <> text_input_id()
  end
end
