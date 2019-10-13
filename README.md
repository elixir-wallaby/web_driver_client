# WebDriverClient

WIP [WebDriver] client for Elixir.

## Testing

One of the goals of this project is to have good test
coverage. This comes through the following types of tests.

### Unit test

The unit test suite can be run with the following command.

```
mix test
```

### Integration tests

Although each webdriver implementation should be the same in theroy, it's good to double-check that this library actually works. The following webdriver implementations are supported via the test suite.

Note: This project does not start any WebDriver program. Those need to be started separately.

#### ChromeDriver

To install ChromeDriver on OS X:

```
$ brew cask install chromedriver
```

Before running test suite, start up chromedriver

```
$ chomedriver
```

Then to run the integration tests, run:

```
$ mix test --only integration_test_driver:chromedriver
```

#### PhantomJS

To install PhantomJS on OS X:

```
$ brew cask install phantomjs
```

Before running test suite, start up phantomjs

```
$ phantomjs --wd
```

Then to run the integration tests, run:

```
$ mix test --only integration_test_driver:phantomjs
```

#### Selenium

To install ChromeDriver on OS x:

```
$ brew install selenium-server-standalone
```

You also need to install the webdriver servers

For firefox:
```
$ brew install geckodriver
```

For chrome:
```
$ brew install chromedriver
```

Before running test suite, start up selenium

```
$ selenium-server
```

Then to run the integration tests, run:

```
$ mix test --only integration_test_driver:selenium
```

If you'd like to run only the selenium tests for chrome, run:

```
$ mix test --only integration_test_driver_browser:selenium-chrome
```

And to only run selenium tests for firefox, run:

```
$ mix test --only integration_test_driver_browser:selenium-firefox
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `web_driver_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:web_driver_client, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/web_driver_client](https://hexdocs.pm/web_driver_client).

[WebDriver]: https://w3c.github.io/webdriver/
