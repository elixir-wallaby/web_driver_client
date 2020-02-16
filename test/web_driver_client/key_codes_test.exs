defmodule WebDriverClient.KeyCodesTest do
  use ExUnit.Case, async: true

  alias WebDriverClient.KeyCodes

  test "key_code_atoms_union/0 generates ast for the union of all of the key_code atoms" do
    assert KeyCodes.key_code_atoms_union() |> Macro.to_string() ==
             ":null | :cancel | :help | :backspace | :tab | :clear | :return | :enter | :shift | :left_shift | :control | :left_control | :alt | :left_alt | :pause | :escape | :space | :page_up | :page_down | :end | :home | :left | :arrow_left | :up | :arrow_up | :right | :arrow_right | :down | :arrow_down | :insert | :delete | :semicolon | :equals | :numpad0 | :numpad1 | :numpad2 | :numpad3 | :numpad4 | :numpad5 | :numpad6 | :numpad7 | :numpad8 | :numpad9 | :multiply | :add | :separator | :subtract | :decimal | :divide | :f1 | :f2 | :f3 | :f4 | :f5 | :f6 | :f7 | :f8 | :f9 | :f10 | :f11 | :f12 | :meta | :command | :left_meta | :right_shift | :right_control | :right_alt | :right_meta | :numpad_page_up | :numpad_page_down | :numpad_end | :numpad_home | :numpad_left | :numpad_up | :numpad_right | :numpad_down | :numpad_insert | :numpad_delete"
  end
end
