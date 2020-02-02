defmodule WebDriverClient.IntegrationTesting.TestPages.IndexPage do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.TestPages.Server

  @spec url :: String.t()
  def url do
    Server.get_base_url()
  end

  @spec title :: String.t()
  def title do
    "I'm the index page"
  end
end
