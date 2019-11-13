defmodule WebDriverClient.JSONWireProtocolClient.TestResponses do
  @moduledoc false
  use ExUnitProperties

  def fetch_window_size_response do
    window_size_response() |> map(&Jason.encode!/1)
  end

  def set_window_size_response do
    blank_value_response() |> map(&Jason.encode!/1)
  end

  defp blank_value_response do
    constant(%{"value" => nil})
  end

  defp window_size_response do
    fixed_map(%{
      "value" =>
        fixed_map(%{
          "width" => integer(0..1000),
          "height" => integer(0..1000)
        })
    })
  end
end
