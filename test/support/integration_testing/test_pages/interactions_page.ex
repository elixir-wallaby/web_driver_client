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

  @spec css_selector_for_open_confirm_button :: String.t()
  def css_selector_for_open_confirm_button do
    "#btn-open-confirm"
  end

  @spec css_selector_for_open_prompt_button :: String.t()
  def css_selector_for_open_prompt_button do
    "#btn-open-prompt"
  end

  @spec css_selector_for_confirm_prompt_output :: String.t()
  def css_selector_for_confirm_prompt_output do
    "#confirm-prompt-result"
  end

  @spec css_selector_for_prompt_output :: String.t()
  def css_selector_for_prompt_output do
    "#prompt-result"
  end

  @spec alert_text :: String.t()
  def alert_text do
    "Hi, I'm an alert"
  end

  @spec prompt_text :: String.t()
  def prompt_text do
    "Please enter your name"
  end

  @spec confirm_accepted_result_text :: String.t()
  def confirm_accepted_result_text do
    "Yes, they're sure"
  end

  @spec confirm_dismissed_result_text :: String.t()
  def confirm_dismissed_result_text do
    "Not so much"
  end
end
