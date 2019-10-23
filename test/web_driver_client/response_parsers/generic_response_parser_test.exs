defmodule WebDriverClient.ResponseParsers.GenericResponseParserTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.ResponseParsers.GenericResponseParser
  alias WebDriverClient.Responses.GenericResponse

  test "parse/1 returns {:ok, GenericResponse.t()} with valid webdriver api response" do
    response_body = %{
      "sessionId" => "7c88c2b04381c30b33fb772ca5f6380a",
      "value" => "http://www.google.com",
      "status" => 0
    }

    value = Map.fetch!(response_body, "value")
    status = Map.fetch!(response_body, "status")
    session_id = Map.fetch!(response_body, "sessionId")

    assert {:ok, %GenericResponse{session_id: ^session_id, value: ^value, status: ^status}} =
             GenericResponseParser.parse(response_body)
  end

  test "parse/1 returns {:ok, GenericResponse.t()} with valid json wire protocol response" do
    response_body = %{
      "value" => "http://www.google.com"
    }

    value = Map.fetch!(response_body, "value")

    assert {:ok, %GenericResponse{session_id: nil, value: ^value, status: nil}} =
             GenericResponseParser.parse(response_body)
  end

  test "parse/1 returns :error on unexpected response" do
    assert :error = GenericResponseParser.parse("foo")
  end
end
