defmodule WebDriverClient.ConfigTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.Config

  test "build/1 sets the opts on the struct" do
    base_url = "http://www.foo.com:8000"

    assert %Config{base_url: ^base_url} = Config.build(base_url: base_url)
  end

  test "build/1 raises a key error if base url is not given" do
    assert_raise KeyError, fn ->
      Config.build([])
    end
  end
end
