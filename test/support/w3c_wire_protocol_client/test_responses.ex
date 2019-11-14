defmodule WebDriverClient.W3CWireProtocolClient.TestResponses do
  @moduledoc false
  use ExUnitProperties

  def fetch_window_rect_response do
    window_rect_response() |> map(&Jason.encode!/1)
  end

  def set_window_rect_response do
    window_rect_response() |> map(&Jason.encode!/1)
  end

  def fetch_current_url_response do
    fixed_map(%{"value" => url()}) |> map(&Jason.encode!/1)
  end

  defp window_rect_response do
    fixed_map(%{
      "value" =>
        fixed_map(%{
          "x" => integer(),
          "y" => integer(),
          "width" => integer(0..1000),
          "height" => integer(0..1000)
        })
    })
  end

  defp url do
    constant("http://foo.com")
  end
end
