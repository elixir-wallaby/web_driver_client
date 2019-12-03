{:ok, _} = WebDriverClient.IntegrationTesting.TestPages.Server.start_link()

ExUnit.configure(exclude: [integration: true])
ExUnit.start()
