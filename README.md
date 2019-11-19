# WebDriverClient
[![codecov](https://codecov.io/gh/aaronrenner/web_driver_client/branch/master/graph/badge.svg)](https://codecov.io/gh/aaronrenner/web_driver_client)

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

Although each webdriver implementation should be the same in theroy, it's good to double-check that this library actually works. The following webdriver implementations are supported via the test suite:

* `chromedriver`
* `phantomjs`
* `selenium_2`
* `selenium_3`

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
$ mix test --only integration_test_driver:selenium_3
```

If you'd like to run only the selenium tests for chrome, run:

```
$ mix test --only integration_test_driver_browser:selenium_3-chrome
```

And to only run selenium tests for firefox, run:

```
$ mix test --only integration_test_driver_browser:selenium_3-firefox
```

##### Selenium 2
If you'd like to run integration tests for `selenium_2`, just replace `selenium_3` with
`selenium_2`.

```
$ mix test --only integration_test_driver:selenium_2
```

#### Running on remote webdriver servers

Sometimes it's nice to be able to run against a remote webdriver server.
Here's an example that runs the tests against a docker container.

1. Start the docker container for the webdriver server

    ```
    $ docker run -p 4446:4444 --shm-size=2g selenium/standalone-chrome:3
    ```

2. Run the tests

    ```
    $ SELENIUM_3_BASE_URL="http://localhost:4446/wd/hub" TEST_SERVER_HOSTAME="host.docker.internal" mix test --only integration_test_driver_browser:selenium_3-chrome
    ```

    The environment variables work like this:

    * `<DRIVER_NAME>_BASE_URL` - The base url for the webdriver server to run
       against. Can also use `WEBDRIVER_BASE_URL` to set this across all scenarios.
    * ` TEST_SERVER_HOSTNAME` - The hostname the webdriver server should use to access
      the machine that's running the test suite.

        The test suite starts up a test HTTP server, but when using a remote webdriver
        server, the webdriver server needs to where the test pages live. When running in
        docker for Mac, the hostname of the host computer is `host.docker.internal`.



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
