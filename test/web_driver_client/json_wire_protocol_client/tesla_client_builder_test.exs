defmodule WebDriverClient.JSONWireProtocolClient.TeslaClientBuilderTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import ExUnit.CaptureLog
  import Plug.Conn

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.JSONWireProtocolClient.Response.Status
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.JSONWireProtocolClient.TestResponses
  alias WebDriverClient.JSONWireProtocolClient.WebDriverError
  alias WebDriverClient.UnexpectedResponseError

  @moduletag :bypass
  @moduletag :capture_log

  @json_content_type "application/json"

  test "build/1 builds a client with the config's base url", %{bypass: bypass} do
    config = Config.build(base_url: bypass_url(bypass))
    client = TeslaClientBuilder.build(config)

    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      send_resp(conn, 200, "")
    end)

    Tesla.get(client, "/")
  end

  defmodule TestState do
    @moduledoc false
    defstruct [:communication_error, :content_type, :response_body, :status_code, :jwp_status]

    @type content_type :: String.t()
    @type response_body :: {:valid_json, map()} | {:other, String.t()}
    @type status_code :: integer()
    @type jwp_status :: integer()

    @type t :: %__MODULE__{
            communication_error: nil | :server_down | :nonexistent_domain,
            content_type: content_type,
            response_body: response_body,
            status_code: status_code,
            jwp_status: jwp_status
          }
  end

  defguardp is_no_content_status_code(status_code)
            when is_integer(status_code) and status_code in [204, 304]

  property "build/1 builds a client that returns the appropriate errors in various scenarios", %{
    bypass: bypass,
    config: config
  } do
    check all state <- test_state() do
      Bypass.up(bypass)
      path = "/" <> generate_test_id()
      set_up_bypass_from_state(state, bypass, path)

      client =
        config
        |> update_config_from_state(state)
        |> TeslaClientBuilder.build()

      case state do
        %TestState{
          communication_error: nil,
          content_type: @json_content_type,
          response_body: {:valid_json, %{"value" => _, "status" => jwp_status} = parsed_body},
          status_code: status_code,
          jwp_status: jwp_status
        }
        when not is_no_content_status_code(status_code) and jwp_status == 0 ->
          {:ok, expected_response} = ResponseParser.parse_response(parsed_body)

          assert {:ok, %Env{body: ^expected_response, status: ^status_code}} =
                   Tesla.get(client, path)

        %TestState{communication_error: :server_down} ->
          assert {:error, %HTTPClientError{reason: :econnrefused}} = Tesla.get(client, path)

        %TestState{communication_error: :nonexistent_domain} ->
          assert {:error, %HTTPClientError{reason: :nxdomain}} = Tesla.get(client, path)

        %TestState{
          communication_error: nil,
          content_type: @json_content_type,
          response_body: {:valid_json, %{"value" => _, "status" => jwp_status}},
          status_code: status_code,
          jwp_status: jwp_status
        }
        when jwp_status > 0 ->
          expected_reason = Status.reason_atom(jwp_status)

          assert {:error,
                  %WebDriverError{reason: ^expected_reason, http_status_code: ^status_code}} =
                   Tesla.get(client, path)

        %TestState{
          communication_error: nil
        } ->
          assert {:error, %UnexpectedResponseError{}} = Tesla.get(client, path)
      end
    end
  end

  test "logs requests when debug is true", %{bypass: bypass, config: config} do
    client =
      config
      |> struct!(debug?: true)
      |> TeslaClientBuilder.build()

    Bypass.down(bypass)

    refute capture_log(fn ->
             Tesla.get(client, "/")
           end) == ""
  end

  test "does not log requests when debug is false", %{bypass: bypass, config: config} do
    client =
      config
      |> struct!(debug?: false)
      |> TeslaClientBuilder.build()

    Bypass.down(bypass)

    assert capture_log(fn ->
             Tesla.get(client, "/")
           end) == ""
  end

  @spec set_up_bypass_from_state(TestState.t(), Bypass.t(), String.t()) :: :ok
  defp set_up_bypass_from_state(
         %TestState{communication_error: :server_down},
         %Bypass{} = bypass,
         _path
       ) do
    Bypass.down(bypass)

    :ok
  end

  defp set_up_bypass_from_state(
         %TestState{communication_error: nil} = state,
         %Bypass{} = bypass,
         path
       ) do
    Bypass.expect_once(bypass, "GET", path, fn conn ->
      conn
      |> put_response_body_from_state(state)
      |> put_content_type_from_state(state)
      |> send_resp()
    end)
  end

  defp set_up_bypass_from_state(_, _, _path) do
    :ok
  end

  defp put_response_body_from_state(conn, %TestState{
         response_body: {:valid_json, to_encode},
         status_code: status_code
       }) do
    json = Jason.encode!(to_encode)

    resp(conn, status_code, json)
  end

  defp put_response_body_from_state(conn, %TestState{
         response_body: {:other, body},
         status_code: status_code
       }) do
    resp(conn, status_code, body)
  end

  defp put_content_type_from_state(conn, %TestState{content_type: nil}), do: conn

  defp put_content_type_from_state(conn, %TestState{content_type: content_type}) do
    put_resp_content_type(conn, content_type)
  end

  @spec update_config_from_state(Config.t(), TestState.t()) :: Config.t()
  defp update_config_from_state(%Config{} = config, %TestState{
         communication_error: :nonexistent_domain
       }) do
    %Config{config | base_url: "http://does.not.exist"}
  end

  defp update_config_from_state(%Config{} = config, %TestState{}) do
    config
  end

  @known_status_codes Enum.flat_map(100..599, fn status_code ->
                        try do
                          _ = Plug.Conn.Status.reason_atom(status_code)
                          [status_code]
                        rescue
                          ArgumentError ->
                            []
                        end
                      end)

  defp known_status_codes, do: @known_status_codes

  @known_jwp_status_codes Enum.flat_map(1..40, fn jwp_status_code ->
                            try do
                              _ = Status.reason_atom(jwp_status_code)
                              [jwp_status_code]
                            rescue
                              ArgumentError ->
                                []
                            end
                          end)

  defp known_jwp_status_codes, do: @known_jwp_status_codes

  @typep test_id :: String.t()

  @spec generate_test_id :: test_id
  defp generate_test_id do
    string(:alphanumeric, length: 40)
    |> Enum.take(1)
    |> List.first()
  end

  @spec test_state :: StreamData.t(TestState.t())
  def test_state do
    frequency([
      {9, server_response_test_state()},
      {1, communication_error_test_state()}
    ])
  end

  @spec communication_error_test_state :: StreamData.t(TestState.t())
  defp communication_error_test_state do
    %{
      communication_error: member_of([:server_down, :nonexistent_domain])
    }
    |> fixed_map()
    |> map(&struct!(TestState, &1))
  end

  @spec server_response_test_state :: StreamData.t(TestState.t())
  defp server_response_test_state do
    gen all jwp_status <-
              frequency([
                {9, constant(0)},
                {1, member_of(known_jwp_status_codes())}
              ]),
            test_state <-
              %{
                content_type: content_type(),
                status_code:
                  frequency([
                    {4, constant(200)},
                    {1, member_of(known_status_codes())}
                  ]),
                jwp_status: constant(jwp_status),
                response_body:
                  frequency([
                    {4,
                     {:valid_json, TestResponses.jwp_response(nil, status: constant(jwp_status))}},
                    {2,
                     {:valid_json,
                      scale(
                        map_of(string(:alphanumeric), string(:alphanumeric)),
                        &trunc(:math.log(&1))
                      )}},
                    {1, {:other, non_json_string()}}
                  ])
              }
              |> fixed_map()
              |> map(&struct!(TestState, &1)) do
      test_state
    end
  end

  @spec content_type :: StreamData.t(String.t() | nil)
  defp content_type do
    member_of([
      @json_content_type,
      "text/plain",
      nil
    ])
  end

  @spec non_json_string :: StreamData.t(String.t())
  defp non_json_string do
    constant("foo")
  end
end
