defmodule WebDriverClient.JSONWireProtocolClient.ResponseParserTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.Response
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TestResponses
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseError

  property "parse_response/1 returns {:ok, %Response{}} on valid JWP response" do
    check all response <- jwp_response() do
      expected_status = Map.fetch!(response, "status")
      expected_value = Map.fetch!(response, "value")
      expected_session_id = Map.get(response, "sessionId")

      assert {:ok,
              %Response{
                session_id: ^expected_session_id,
                status: ^expected_status,
                value: ^expected_value,
                original_body: ^response
              }} = ResponseParser.parse_response(response)
    end
  end

  property "parse_response/1 returns {:error, %UnexpectedResponseError{}} on invalid JWP response" do
    check all response <-
                one_of([
                  invalid_jwp_response(),
                  member_of([1, [], "foo"])
                ]) do
      assert {:error,
              %UnexpectedResponseError{
                response_body: ^response
              }} = ResponseParser.parse_response(response)
    end
  end

  property "parse_value/1 returns {:ok, value}" do
    check all value <-
                one_of([
                  integer(),
                  list_of(url(), max_length: 3),
                  map_of(
                    string(:alphanumeric, max_length: 10),
                    string(:alphanumeric, max_length: 10),
                    max_length: 3
                  )
                ]),
              response <- TestResponses.jwp_response(constant(value)) do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:ok, ^value} = ResponseParser.parse_value(parsed_response)
    end
  end

  property "parse_url/1 returns {:ok, url} when result is a string" do
    check all url <- url(),
              response <- TestResponses.jwp_response(constant(url)) do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:ok, ^url} = ResponseParser.parse_url(parsed_response)
    end
  end

  property "parse_url/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                [
                  integer(),
                  list_of(url(), max_length: 3),
                  map_of(
                    string(:alphanumeric, max_length: 10),
                    string(:alphanumeric, max_length: 10),
                    max_length: 3
                  )
                ]
                |> one_of()
                |> TestResponses.jwp_response() do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_url(parsed_response)
    end
  end

  property "parse_size/1 returns {:ok, %Size{}} on valid response" do
    check all %{"width" => width, "height" => height} = value <-
                fixed_map(%{
                  "width" => integer(0..1000),
                  "height" => integer(0..1000)
                }),
              response <- TestResponses.jwp_response(constant(value)) do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:ok, %Size{width: ^width, height: ^height}} =
               ResponseParser.parse_size(parsed_response)
    end
  end

  property "parse_size/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <-
                %{
                  "width" => string(:alphanumeric, max_length: 3),
                  "height" => string(:alphanumeric, max_length: 3)
                }
                |> fixed_map()
                |> TestResponses.jwp_response() do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_size(parsed_response)
    end
  end

  property "parse_log_entries/1 returns {:ok [%LogEntry{}]} when all log entries are valid" do
    check all unparsed_log_entries <- list_of(TestResponses.log_entry(), max_length: 10),
              response <- TestResponses.jwp_response(constant(unparsed_log_entries)) do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      expected_log_entries =
        Enum.map(unparsed_log_entries, fn %{
                                            "level" => level,
                                            "message" => message,
                                            "timestamp" => timestamp
                                          } = raw_entry ->
          %LogEntry{
            level: level,
            message: message,
            timestamp: DateTime.from_unix!(timestamp, :millisecond),
            source: Map.get(raw_entry, "source")
          }
        end)

      assert {:ok, ^expected_log_entries} = ResponseParser.parse_log_entries(parsed_response)
    end
  end

  property "parse_log_entries/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <- log_entries_with_invalid_responses() |> TestResponses.jwp_response() do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_log_entries(parsed_response)
    end
  end

  property "parse_elements/1 returns {:ok [%Element{}]} when all log entries are valid" do
    check all unparsed_elements <- list_of(TestResponses.element(), max_length: 10),
              response <- TestResponses.jwp_response(constant(unparsed_elements)) do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      expected_elements =
        Enum.map(unparsed_elements, fn %{
                                         "ELEMENT" => element_id
                                       } ->
          %Element{
            id: element_id
          }
        end)

      assert {:ok, ^expected_elements} = ResponseParser.parse_elements(parsed_response)
    end
  end

  property "parse_elements/1 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    check all response <- elements_with_invalid_responses() |> TestResponses.jwp_response() do
      {:ok, parsed_response} = ResponseParser.parse_response(response)

      assert {:error, %UnexpectedResponseError{response_body: ^response}} =
               ResponseParser.parse_elements(parsed_response)
    end
  end

  test "parse_fetch_sessions_response/2 returns {:ok [%Session{}]} when all sessions are valid" do
    config = TestData.config() |> pick()
    response = TestResponses.fetch_sessions_response() |> pick() |> Jason.decode!()

    session_id =
      response
      |> Map.fetch!("value")
      |> List.first()
      |> Map.fetch!("id")

    {:ok, parsed_response} = ResponseParser.parse_response(response)

    assert {:ok, [%Session{id: ^session_id, config: ^config}]} =
             ResponseParser.parse_fetch_sessions_response(parsed_response, config)
  end

  test "parse_fetch_sessions_response/2 returns {:error, %UnexpectedResponseError{}} on an invalid response" do
    config = TestData.config() |> pick()
    response = %{} |> constant() |> TestResponses.jwp_response() |> pick()

    {:ok, parsed_response} = ResponseParser.parse_response(response)

    assert {:error, %UnexpectedResponseError{response_body: ^response}} =
             ResponseParser.parse_fetch_sessions_response(parsed_response, config)
  end

  test "parse_start_session_response/2 returns {:ok, Session.t()} on know response" do
    config = TestData.config() |> pick()
    response = TestResponses.start_session_response() |> pick() |> Jason.decode!()
    session_id = Map.fetch!(response, "sessionId")

    {:ok, parsed_response} = ResponseParser.parse_response(response)

    assert {:ok, %Session{id: ^session_id, config: ^config}} =
             ResponseParser.parse_start_session_response(parsed_response, config)
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

  defp url do
    string(:alphanumeric)
  end

  defp invalid_jwp_response do
    one_of([
      # missing status
      constant(%{"value" => 0}),
      # missing value
      constant(%{"status" => 0}),
      # invalid type for status
      constant(%{"value" => nil, "status" => "a"}),
      # invalid type for sessionId
      constant(%{"sessionId" => 3, "value" => nil, "status" => 0}),
      constant(%{})
    ])
  end

  defp jwp_response do
    %{
      "sessionId" =>
        one_of([
          unshrinkable(TestResponses.session_id()),
          nil,
          :remove_from_payload
        ]),
      "status" => TestResponses.status_int(),
      "value" =>
        scale(
          term(),
          &trunc(:math.log(&1))
        )
    }
    |> fixed_map()
    |> map(fn response ->
      response
      |> Enum.reject(&match?({_, :remove_from_payload}, &1))
      |> Map.new()
    end)
  end
end
