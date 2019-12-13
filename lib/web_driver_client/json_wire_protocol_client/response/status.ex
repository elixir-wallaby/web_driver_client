defmodule WebDriverClient.JSONWireProtocolClient.Response.Status do
  @moduledoc false

  statuses = %{
    0 => :success,
    6 => :no_such_driver,
    7 => :no_such_element,
    8 => :no_such_frame,
    9 => :unknown_command,
    10 => :stale_element_reference,
    11 => :element_not_visible,
    12 => :invalid_element_state,
    13 => :unknown_error,
    15 => :element_is_not_selectable,
    17 => :javascript_error,
    19 => :xpath_lookup_error,
    21 => :timeout,
    23 => :no_such_window,
    24 => :invalid_cookie_domain,
    25 => :unable_to_set_cookie,
    26 => :unexpected_alert_open,
    27 => :no_alert_open_error,
    28 => :script_timeout,
    29 => :invalid_element_coordinates,
    30 => :ime_not_available,
    31 => :ime_engine_activation_failed,
    32 => :invalid_selector,
    33 => :session_not_created_exception,
    34 => :move_target_out_of_bounds
  }

  @spec reason_atom(integer) :: atom
  def reason_atom(code)

  for {code, reason} <- statuses do
    def reason_atom(unquote(code)), do: unquote(reason)
  end

  def reason_atom(code) do
    raise ArgumentError, "unknown status code #{inspect(code)}"
  end
end
