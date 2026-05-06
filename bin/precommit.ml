(*
 * Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the FSF, either version 3 of the License, or (at your option) any later version.
 * See the LICENSE file in the root of this repository for full license text or
 * visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
 *)

let print_help () =
  print_endline "Usage: ggh pre-commit [COMMAND] [OPTIONS...]\n";
  print_endline "Commands:";
  print_endline "  install            runs pre-commit install";
  print_endline "  help               Print this help message and exit"

exception PreCommitError of string

let install () =
  let process =
    Unix.create_process_env "pre-commit" [| "install" |]
      [| "GIT_CONFIG=/dev/null" |]
      Unix.stdin Unix.stdout Unix.stderr
  in
  match Unix.waitpid [] process with
  | _, Unix.WEXITED 0 -> print_endline "Successfully installed"
  | _, _ -> raise (PreCommitError "unable to install pre-commit")

let exec (args : string array) =
  let cmd = try Some (Array.get args 1) with Invalid_argument _ -> None in
  match cmd with
  | None | Some "help" -> print_help ()
  | Some "install" -> install ()
  | Some c -> raise (PreCommitError ("unknown pre-commit command" ^ c))
