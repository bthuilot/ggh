(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

let print_help () =
  print_endline "Usage: ggh pre-commit [COMMAND] [OPTIONS...]\n";
  print_endline "Commands:";
  print_endline "  install            runs pre-commit install";
  print_endline "";
  print_endline "Options:";
  print_endline "  --help             Print this help message and exit."

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
  | None | Some "--help" -> print_help ()
  | Some "install" -> install ()
  | Some c -> raise (PreCommitError ("unknown pre-commit command" ^ c))
