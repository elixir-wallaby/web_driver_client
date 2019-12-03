defmodule WebDriverClient.IntegrationTesting.TestPages.LoggingPage do
  @moduledoc false

  alias WebDriverClient.IntegrationTesting.TestPages.Server

  @spec url :: String.t()
  def url do
    Path.join([Server.get_base_url(), "logging.html"])
  end
end
