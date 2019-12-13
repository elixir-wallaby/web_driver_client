defmodule WebDriverClient.JSONWireProtocolClient.Response.StatusTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.JSONWireProtocolClient.Response.Status

  test "reason_atom/1 returns the appropriate atom from a code" do
    assert :success = Status.reason_atom(0)
  end

  test "reason_atom/1 raises an argument error on unknown code" do
    assert_raise ArgumentError, fn ->
      Status.reason_atom(-1)
    end
  end
end
