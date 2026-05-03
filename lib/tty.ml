(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
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
