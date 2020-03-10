defmodule WebDriverClient.ConfigTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.Config

  @default_protocol :w3c

  @base_url "http://example.com"

  test "build/2 sets the opts on the struct" do
    base_url = "http://www.foo.com:8000"
    protocol = :jwp
    debug = true
    http_client_options = [pool: :foo]

    assert %Config{
             base_url: ^base_url,
             protocol: ^protocol,
             debug?: ^debug,
             http_client_options: ^http_client_options
           } =
             Config.build(base_url,
               protocol: protocol,
               debug: debug,
               http_client_options: http_client_options
             )
  end

  test "build/1 defaults protocol to w3c" do
    assert %Config{protocol: @default_protocol} = Config.build(@base_url)
  end

  test "build/1 defaults debug to false" do
    assert %Config{debug?: false} = Config.build(@base_url)
  end

  test "put_protocol/2 allows updating the protocol to w3c" do
    protocol = :w3c

    config =
      @base_url
      |> Config.build()
      |> Config.put_protocol(protocol)

    assert %Config{protocol: ^protocol} = config
  end

  test "put_protocol/2 allows updating the protocol to jwp" do
    protocol = :w3c

    config =
      @base_url
      |> Config.build()
      |> Config.put_protocol(protocol)

    assert %Config{protocol: ^protocol} = config
  end

  test "put_protocol/2 disallows updating protocol to unknown protocol" do
    protocol = :invalid
    config = Config.build(@base_url)

    assert_raise FunctionClauseError, fn ->
      Config.put_protocol(config, protocol)
    end
  end
end
