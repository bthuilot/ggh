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
  Log.info "prompting user for msg: %s" msg;
  print_string (msg ^ " [Y/n]: ");
  flush stdout;
  let yes = read_line () |> is_yes in
  Log.info "user responded %B" yes;
  yes
