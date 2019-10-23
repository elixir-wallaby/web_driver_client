defmodule WebDriverClient.Guards do
  @moduledoc false

  defguard is_session_id(term) when is_binary(term)

  defguard is_url(term) when is_binary(term)
end
