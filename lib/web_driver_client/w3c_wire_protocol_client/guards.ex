defmodule WebDriverClient.W3CWireProtocolClient.Guards do
  @moduledoc false

  defguard is_session_id(term) when is_binary(term)

  defguard is_url(term) when is_binary(term)

  defguard is_element_location_strategy(term) when term in [:css_selector, :xpath]

  defguard is_element_selector(term) when is_binary(term)

  defguard is_attribute_name(term) when is_binary(term)

  defguard is_property_name(term) when is_binary(term)

  defguard is_cookie_name(term) when is_binary(term)

  defguard is_cookie_value(term) when is_binary(term)
end
