defmodule WebDriverClient.W3CWireProtocolClient.ResponseParserTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WebDriverClient.Element
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.Session
  alias WebDriverClient.TestData
  alias WebDriverClient.W3CWireProtocolClient.Cookie
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.Response
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.ServerStatus
  alias WebDriverClient.W3CWireProtocolClient.TestResponses
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  property "parse_value/1 returns {:ok, url} when result is a string" do
    check all value <-
                one_of([
                  integer(),
                  list_of(url(), max_length: 3),
                  map_of(
                    string(:alphanumeric, max_length: 10),
                    string(:alphanumeric, max_length: 10),
                    max_length: 3
                  )
                ]) do
      response = %{"value" => value}
      w3c_response = build_w3c_response(response)

      assert {:ok, ^value} = ResponseParser.parse_value(w3c_response)
    end
  end

  test "parse_value/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    for response <- [[], %{}] do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_value(w3c_response)
    end
  end

  property "parse_url/1 returns {:ok, url} when result is a string" do
    check all url <- url() do
      response = %{"value" => url}
      w3c_response = build_w3c_response(response)

      assert {:ok, ^url} = ResponseParser.parse_url(w3c_response)
    end
  end

  property "parse_url/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      one_of([
                        integer(),
                        list_of(url(), max_length: 3),
                        map_of(
                          string(:alphanumeric, max_length: 10),
                          string(:alphanumeric, max_length: 10),
                          max_length: 3
                        )
                      ])
                  })
                ]) do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_url(w3c_response)
    end
  end

  property "parse_boolean/1 returns {:ok, boolean} when result is a boolean" do
    check all boolean <- boolean() do
      response = %{"value" => boolean}
      w3c_response = build_w3c_response(response)

      assert {:ok, ^boolean} = ResponseParser.parse_boolean(w3c_response)
    end
  end

  property "parse_boolean/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      one_of([
                        integer(),
                        member_of(["true", "false"]),
                        map_of(
                          string(:alphanumeric, max_length: 10),
                          string(:alphanumeric, max_length: 10),
                          max_length: 3
                        )
                      ])
                  })
                ]) do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_boolean(w3c_response)
    end
  end

  property "parse_rect/1 returns {:ok, %Rect{}} on valid response" do
    check all x <- integer(),
              y <- integer(),
              width <- integer(0..1000),
              height <- integer(0..1000) do
      response = %{"value" => %{"x" => x, "y" => y, "width" => width, "height" => height}}
      w3c_response = build_w3c_response(response)

      assert {:ok, %Rect{x: ^x, y: ^y, width: ^width, height: ^height}} =
               ResponseParser.parse_rect(w3c_response)
    end
  end

  property "parse_rect/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      fixed_map(%{
                        "x" => string(:alphanumeric),
                        "y" => string(:alphanumeric),
                        "width" => string(:alphanumeric),
                        "height" => string(:alphanumeric)
                      })
                  })
                ]) do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_rect(w3c_response)
    end
  end

  property "parse_log_entries/1 returns {:ok [%LogEntry{}]} when all log entries are valid" do
    check all unparsed_log_entries <- list_of(TestResponses.log_entry(), max_length: 10) do
      response = %{"value" => unparsed_log_entries}
      w3c_response = build_w3c_response(response)

      expected_log_entries =
        Enum.map(unparsed_log_entries, fn %{
                                            "level" => level,
                                            "message" => message,
                                            "timestamp" => timestamp
                                          } ->
          %LogEntry{
            level: level,
            message: message,
            timestamp: DateTime.from_unix!(timestamp, :millisecond)
          }
        end)

      assert {:ok, ^expected_log_entries} = ResponseParser.parse_log_entries(w3c_response)
    end
  end

  property "parse_log_entries/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" => log_entries_with_invalid_responses()
                  })
                ]) do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_log_entries(w3c_response)
    end
  end

  property "parse_element/1 returns {:ok, %Element{}} on a valid response" do
    check all %{@web_element_identifier => element_id} = value <- TestResponses.element() do
      response = %{"value" => value}
      w3c_response = build_w3c_response(response)

      assert {:ok, %Element{id: ^element_id}} = ResponseParser.parse_element(w3c_response)
    end
  end

  property "parse_element/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all value <-
                %{
                  @web_element_identifier => member_of([1, %{}, []])
                }
                |> fixed_map() do
      response = %{"value" => value}
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_element(w3c_response)
    end
  end

  property "parse_elements/1 returns {:ok [%Element{}]} when all log entries are valid" do
    check all unparsed_elements <- list_of(TestResponses.element(), max_length: 10) do
      response = %{"value" => unparsed_elements}
      w3c_response = build_w3c_response(response)

      expected_elements =
        Enum.map(unparsed_elements, fn %{
                                         @web_element_identifier => element_id
                                       } ->
          %Element{
            id: element_id
          }
        end)

      assert {:ok, ^expected_elements} = ResponseParser.parse_elements(w3c_response)
    end
  end

  property "parse_elements/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" => elements_with_invalid_responses()
                  })
                ]) do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_elements(w3c_response)
    end
  end

  test "parse_fetch_sessions_response/2 returns {:ok [%Session{}]} when all sessions are valid" do
    config = TestData.config() |> pick()
    resp = TestResponses.fetch_sessions_response() |> pick() |> Jason.decode!()
    w3c_response = build_w3c_response(resp)

    session_id =
      resp
      |> Map.fetch!("value")
      |> List.first()
      |> Map.fetch!("id")

    assert {:ok, [%Session{id: ^session_id, config: ^config}]} =
             ResponseParser.parse_fetch_sessions_response(w3c_response, config)
  end

  test "parse_fetch_sessions_response/2 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    config = TestData.config() |> pick()
    response = %{}
    w3c_response = build_w3c_response(response)

    assert {:error, %UnexpectedResponseError{response_body: ^response}} =
             ResponseParser.parse_fetch_sessions_response(w3c_response, config)
  end

  test "parse_start_session_response/2 returns {:ok, Session.t()} on known response" do
    config = TestData.config() |> pick()
    resp = TestResponses.start_session_response() |> pick() |> Jason.decode!()
    session_id = get_in(resp, ["value", "sessionId"])
    w3c_response = build_w3c_response(resp)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             ResponseParser.parse_start_session_response(w3c_response, config)
  end

  test "parse_start_session_response/2 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    config = TestData.config() |> pick()
    response = %{}
    w3c_response = build_w3c_response(response)

    assert {:error, %UnexpectedResponseError{response_body: ^response}} =
             ResponseParser.parse_start_session_response(w3c_response, config)
  end

  property "parse_cookies/1 returns {:ok, [%Cookie{}]} when all cookies are valid" do
    check all unparsed_cookies <- list_of(TestResponses.cookie(), max_length: 10) do
      response = %{"value" => unparsed_cookies}
      w3c_response = build_w3c_response(response)

      expected_cookies =
        Enum.map(unparsed_cookies, fn %{"name" => name, "value" => value, "domain" => domain} ->
          %Cookie{name: name, value: value, domain: domain}
        end)

      assert {:ok, ^expected_cookies} = ResponseParser.parse_cookies(w3c_response)
    end
  end

  property "parse_cookies/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" => cookies_with_invalid_responses()
                  })
                ]) do
      w3c_response = build_w3c_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_cookies(w3c_response)
    end
  end

  property "parse_server_status/1 returns {:ok, %ServerStatus{}}" do
    check all json_response <- TestResponses.fetch_server_status_response() do
      response = Jason.decode!(json_response)
      w3c_response = build_w3c_response(response)

      ready? =
        response
        |> Map.fetch!("value")
        |> Map.get("ready", true)

      assert {:ok, %ServerStatus{ready?: ^ready?}} =
               ResponseParser.parse_server_status(w3c_response)
    end
  end

  test "parse_server_status/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    response = %{}
    w3c_response = build_w3c_response(response)

    assert {:error, %UnexpectedResponseError{response_body: ^response}} =
             ResponseParser.parse_cookies(w3c_response)
  end

  defp elements_with_invalid_responses do
    gen all valid_elements <- list_of(TestResponses.element(), max_length: 10),
            invalid_elements <- list_of(constant(%{}), min_length: 1, max_length: 10) do
      [valid_elements, invalid_elements]
      |> List.flatten()
      |> Enum.shuffle()
    end
  end

  defp log_entries_with_invalid_responses do
    gen all valid_log_entries <- list_of(TestResponses.log_entry(), max_length: 10),
            invalid_log_entries <- list_of(constant(%{}), min_length: 1, max_length: 10) do
      [valid_log_entries, invalid_log_entries]
      |> List.flatten()
      |> Enum.shuffle()
    end
  end

  defp cookies_with_invalid_responses do
    gen all valid_cookies <- list_of(TestResponses.cookie(), max_length: 10),
            invalid_cookies <- list_of(constant(%{}), min_length: 1, max_length: 10) do
      [valid_cookies, invalid_cookies]
      |> List.flatten()
      |> Enum.shuffle()
    end
  end

  defp url do
    string(:alphanumeric)
  end

  defp build_w3c_response(parsed_body) do
    %Response{
      body: parsed_body,
      http_response: %HTTPResponse{
        status: 200,
        headers: [],
        body: Jason.encode!(parsed_body)
      }
    }
  end
end
