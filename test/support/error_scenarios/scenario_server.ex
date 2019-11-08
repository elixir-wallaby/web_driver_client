defmodule WebDriverClient.ErrorScenarios.ScenarioServer do
  @moduledoc false
  use Agent

  import Plug.Conn

  alias WebDriverClient.ErrorScenarios.ErrorScenario

  def start_link(_opt) do
    Agent.start_link(fn -> nil end)
  end

  def load_scenario(server, %ErrorScenario{} = scenario) do
    Agent.update(server, fn _ -> scenario end)
  end

  def send_scenario_resp(server, conn) do
    scenario = Agent.get(server, & &1)

    conn
    |> put_content_type_from_scenario(scenario)
    |> put_response_body_from_scenario(scenario)
  end

  defp put_response_body_from_scenario(conn, %ErrorScenario{
         response_body: {:valid_json, to_encode},
         status_code: status_code
       }) do
    json = Jason.encode!(to_encode)

    resp(conn, status_code, json)
  end

  defp put_response_body_from_scenario(conn, %ErrorScenario{
         response_body: {:other, body},
         status_code: status_code
       }) do
    resp(conn, status_code, body)
  end

  defp put_content_type_from_scenario(conn, %ErrorScenario{content_type: nil}), do: conn

  defp put_content_type_from_scenario(conn, %ErrorScenario{content_type: content_type}) do
    put_resp_content_type(conn, content_type)
  end
end
