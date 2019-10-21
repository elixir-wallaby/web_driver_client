defmodule WebDriverClient.SessionTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Session
  alias WebDriverClient.TestData

  property "build/1 only allows valid values" do
    check all id <-
                one_of([
                  TestData.session_id(),
                  not_session_id()
                ]),
              config <-
                one_of([
                  TestData.config(),
                  not_config()
                ]) do
      if is_session_id(id) and match?(%Config{}, config) do
        assert %Session{id: ^id, config: ^config} = Session.build(id, config)
      else
        assert_raise FunctionClauseError, fn ->
          Session.build(id, config)
        end
      end
    end
  end

  defp not_session_id do
    one_of([
      nil,
      constant(1),
      constant([])
    ])
  end

  defp not_config do
    one_of([
      nil,
      constant(""),
      constant(%{})
    ])
  end
end
