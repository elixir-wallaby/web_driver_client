defmodule WebDriverClient.ProtocolMismatchErrorTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.ProtocolMismatchError

  test "error is raisable" do
    assert_raise ProtocolMismatchError, fn ->
      raise ProtocolMismatchError, response: :ok, expected_protocol: :jwp, actual_protocol: :w3c
    end
  end
end
