defmodule WebDriverClient.ConfigTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.Config

  @default_protocol :w3c

  @required_opts [base_url: "http://www.foo.com:8000"]

  test "build/1 sets the opts on the struct" do
    base_url = "http://www.foo.com:8000"
    protocol = :jwp
    debug = true

    assert %Config{base_url: ^base_url, protocol: ^protocol, debug?: ^debug} =
             Config.build(base_url: base_url, protocol: protocol, debug: debug)
  end

  test "build/1 raises a KeyError if base url is not given" do
    assert_raise KeyError, fn ->
      Config.build([])
    end
  end

  test "build/1 defaults protocol to w3c" do
    assert %Config{protocol: @default_protocol} = Config.build(@required_opts)
  end

  test "build/1 defaults debug to false" do
    assert %Config{debug?: false} = Config.build(@required_opts)
  end
end
