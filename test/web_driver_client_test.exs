defmodule WebDriverClientTest do
  use ExUnit.Case
  doctest WebDriverClient

  test "greets the world" do
    assert WebDriverClient.hello() == :world
  end
end
