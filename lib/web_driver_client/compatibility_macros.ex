defmodule WebDriverClient.CompatibilityMacros do
  @moduledoc false

  defmacro doc_metadata(opts) do
    if System.version() |> Version.match?(">= 1.7.0") do
      quote do
        @doc unquote(opts)
      end
    end
  end

  defmacro prerelease_moduledoc(opts) do
    if Application.get_env(:web_driver_client, :include_prerelease_docs) do
      quote do
        @moduledoc unquote(opts)
      end
    else
      quote do
        @moduledoc false
      end
    end
  end
end
