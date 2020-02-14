defmodule WebDriverClient.IntegrationTesting.TestPages.InteractionsPage do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.TestPages.Server

  @spec url :: String.t()
  def url do
    Path.join([Server.get_base_url(), "interactions.html"])
  end

  @spec css_selector_for_switchable_text :: String.t()
  def css_selector_for_switchable_text do
    "#switchable-text"
  end

  @spec css_selector_for_switch_text_button :: String.t()
  def css_selector_for_switch_text_button do
    "#btn-switch-text"
  end

  @spec css_selector_for_open_alert_button :: String.t()
  def css_selector_for_open_alert_button do
    "#btn-open-alert"
  end

  @spec alert_text :: String.t()
  def alert_text do
    "Hi, I'm an alert"
  end
end
