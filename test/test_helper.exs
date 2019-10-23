{:ok, _} = WebDriverClient.IntegrationTesting.TestServer.start_link()

ExUnit.configure(exclude: [integration: true])
ExUnit.start()
