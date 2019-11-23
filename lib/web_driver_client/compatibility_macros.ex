defmodule WebDriverClient.CompatibilityMacros do
  @moduledoc false

  defmacro doc_metadata(opts) do
    if System.version() |> Version.match?(">= 1.7.0") do
      quote do
        @doc unquote(opts)
      end
    end
  end
end
