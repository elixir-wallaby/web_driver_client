test:
    FROM +test-setup

    RUN mix test
    RUN mix format --check-formatted

dialyzer:
    FROM +test-setup

    RUN mix dialyzer --plt

integration-test:
    FROM +test-setup

    # Install manually to improve caching
    RUN apk add --no-progress --update docker docker-compose

    COPY docker-compose.yml ./
    WITH DOCKER \
        --compose docker-compose.yml

        RUN TEST_SERVER_HOSTNAME=dockerhost WEBDRIVER_BASE_URL=http://localhost:4445/wd/hub mix test --only integration_test_driver_browser:selenium_3-chrome && \
        TEST_SERVER_HOSTNAME=dockerhost WEBDRIVER_BASE_URL=http://localhost:4446/wd/hub mix test --only integration_test_driver_browser:selenium_3-firefox && \
        TEST_SERVER_HOSTNAME=dockerhost WEBDRIVER_BASE_URL=http://localhost:4447/wd/hub mix test --only integration_test_driver_browser:selenium_2-chrome && \
        TEST_SERVER_HOSTNAME=dockerhost WEBDRIVER_BASE_URL=http://localhost:4448/wd/hub mix test --only integration_test_driver_browser:selenium_2-firefox
    END

test-setup:
    ARG ELIXIR=1.12.2
    ARG OTP=24.0.3
    FROM hexpm/elixir:$ELIXIR-erlang-$OTP-alpine-3.14.0
    WORKDIR /src
    COPY mix.exs .
    COPY mix.lock .
    COPY .formatter.exs .
    RUN mix local.rebar --force
    RUN mix local.hex --force
    RUN mix deps.get

    RUN MIX_ENV=test mix deps.compile

    COPY --dir config lib test ./