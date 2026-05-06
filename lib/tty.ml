(*
 * Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the FSF, either version 3 of the License, or (at your option) any later version.
 * See the LICENSE file in the root of this repository for full license text or
 * visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
 *)

module Log = Dolog.Log

let is_yes (resp : string) : bool =
  resp = "" || String.sub resp 0 1 |> String.lowercase_ascii = "y"

let confirm (msg : string) : bool =
  try
    let tty_in, tty_out = (open_in "/dev/tty", open_out "/dev/tty") in
    begin
      output_string tty_out (msg ^ " [Y/n]: ");
      flush tty_out;
      let line = input_line tty_in in
      close_in tty_in;
      close_out tty_out;
      let yes = is_yes line in
      Log.info "user responded %B" yes;
      yes
    end
  with _ ->
    Log.warn "no tty available, defaulting to false";
    false
