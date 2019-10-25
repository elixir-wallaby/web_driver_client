defmodule WebDriverClient.ConfigTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.Config

  @default_protocol :w3c

  test "build/1 sets the opts on the struct" do
    base_url = "http://www.foo.com:8000"
    protocol = :jwp

    assert %Config{base_url: ^base_url, protocol: ^protocol} =
             Config.build(base_url: base_url, protocol: protocol)
  end

  test "build/1 raises a KeyError if base url is not given" do
    assert_raise KeyError, fn ->
      Config.build([])
    end
  end

  test "build/1 defaults protocol to w3c" do
    opts = [base_url: "http://www.foo.com:8000"]

    assert %Config{protocol: @default_protocol} = Config.build(opts)
  end
end
