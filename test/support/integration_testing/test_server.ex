defmodule WebDriverClient.IntegrationTesting.TestServer do
  @moduledoc false
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def get_base_url do
    port_number = GenServer.call(__MODULE__, :get_port_number)

    "http://#{get_test_server_hostname()}:#{port_number}"
  end

  def get_test_page_url(:logging) do
    Path.join(get_base_url(), "logging.html")
  end

  @impl true
  def init([]) do
    :inets.start()

    config = [
      port: 0,
      server_root: String.to_charlist(Path.absname("./", __DIR__)),
      document_root: String.to_charlist(Path.absname("./test_server/pages", __DIR__)),
      server_name: 'web_driver_client_test',
      directory_index: ['index.html']
    ]

    case :inets.start(:httpd, config) do
      {:ok, pid} ->
        port_number =
          pid
          |> :httpd.info()
          |> Keyword.fetch!(:port)

        Process.link(pid)

        {:ok, %{pid: pid, port_number: port_number}}

      error ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:get_port_number, _from, state) do
    %{port_number: port_number} = state

    {:reply, port_number, state}
  end

  @impl true
  def terminate(_, state) do
    %{pid: pid} = state

    :ok = :inets.stop(:httpd, pid)
  end

  defp get_test_server_hostname do
    System.get_env("TEST_SERVER_HOSTNAME") || "localhost"
  end
end
