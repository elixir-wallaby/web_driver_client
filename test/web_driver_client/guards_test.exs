defmodule WebDriverClient.GuardsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WebDriverClient.Guards

  require WebDriverClient.Guards

  property "is_session_id/1 only returns true on binaries" do
    check all term <- term() do
      if is_binary(term) do
        assert Guards.is_session_id(term)
      else
        refute Guards.is_session_id(term)
      end
    end
  end

  property "is_url/1 only returns true on binaries" do
    check all term <- term() do
      if is_binary(term) do
        assert Guards.is_url(term)
      else
        refute Guards.is_url(term)
      end
    end
  end
end
