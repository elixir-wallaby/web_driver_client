defmodule WebDriverClient.Middleware.UnexpectedStatusCodeErrorHandler do
  @moduledoc false

  alias Tesla.Env
  alias WebDriverClient.UnexpectedStatusCodeError

  @behaviour Tesla.Middleware

  @json_content_type "application/json"

  @impl true
  def call(env, next, _opts) do
    case Tesla.run(env, next) do
      {:ok, %Env{status: status_code} = env} when status_code >= 200 and status_code <= 299 ->
        {:ok, env}

      {:ok, %Env{status: status_code} = env} ->
        parsed_body = parse_body_if_possible(env)

        {:error,
         UnexpectedStatusCodeError.exception(status_code: status_code, response_body: parsed_body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_body_if_possible(%Env{body: body} = env) do
    with true <- decodeable_content_type?(env),
         {:ok, parsed_body} <- Jason.decode(body) do
      parsed_body
    else
      _ ->
        body
    end
  end

  defp decodeable_content_type?(%Env{} = env) do
    case Tesla.get_header(env, "content-type") do
      nil -> false
      content_type -> String.starts_with?(content_type, @json_content_type)
    end
  end
end
