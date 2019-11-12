defmodule WebDriverClient.APIClientCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  use ExUnitProperties

  alias Plug.Conn
  alias Plug.Parsers
  alias WebDriverClient.Config

  setup [:start_bypass, :set_config_from_bypass]

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  def bypass_url(%Bypass{port: port}, path \\ "") do
    "http://localhost:#{port}" |> URI.merge(path) |> to_string()
  end

  defp set_config_from_bypass(%{bypass: %Bypass{} = bypass} = context) do
    [config: config_from_bypass(bypass, context)]
  end

  defp config_from_bypass(%Bypass{} = bypass, context) do
    Config.build(base_url: bypass_url(bypass))
    |> maybe_update_protocol(context)
  end

  defp maybe_update_protocol(%Config{} = config, %{protocol: protocol}) do
    Config.put_protocol(config, protocol)
  end

  defp maybe_update_protocol(%Config{} = config, _) do
    config
  end

  defp start_bypass(%{bypass: true}) do
    {:ok, bypass: Bypass.open()}
  end

  defp start_bypass(_), do: :ok

  def parse_params(%Conn{} = conn) do
    Parsers.call(conn, Parsers.init(parsers: [:json], json_decoder: Jason))
  end

  @type url_prefix :: String.t()

  @spec prefix_base_url_for_multiple_runs(Config.t(), url_prefix) :: {Config.t(), url_prefix}
  def prefix_base_url_for_multiple_runs(%Config{} = config, url_prefix \\ generate_url_prefix())
      when is_binary(url_prefix) do
    config = prepend_prefix_to_base_url(config, url_prefix)
    {config, url_prefix}
  end

  @spec prepend_prefix_to_base_url(Config.t(), url_prefix) :: Config.t()
  defp prepend_prefix_to_base_url(%Config{base_url: base_url} = config, url_prefix)
       when is_binary(url_prefix) do
    base_url = Path.join(base_url, url_prefix)
    %Config{config | base_url: base_url}
  end

  @spec generate_url_prefix :: url_prefix
  defp generate_url_prefix do
    string(:alphanumeric, length: 40)
    |> Enum.take(1)
    |> List.first()
  end
end
