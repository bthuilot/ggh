(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log
module Config = Ggh.Config
module Hooks = Ggh.Hooks

(** [hook_name] is the name of the hook we are executing. It is determined from
    the name of the binary that git executed *)
let parse_hook_name () : string =
  try
    let hook = Sys.getenv "GGH_HOOK_OVERRIDE" in
    Log.warn "hook overriden from enviroment to %s" hook;
    hook
  with Not_found -> Filename.basename Sys.argv.(0)

(** [parse_command] will parse the arguments for the program for the command to
    execute. This is supposed to be called when the program is run as 'ggh', not
    a git hook *)
let parse_command () =
  let n_args = Array.length Sys.argv in
  if n_args < 2 then (
    Printf.printf "please provide an argument\n";
    exit 1)
  else
    let cmd = Sys.argv.(1) and sub_args = Array.sub Sys.argv 1 (n_args - 1) in
    let exit_code =
      match cmd with
      | "--help" ->
          Info.help ();
          0
      | "--version" ->
          Info.version ();
          0
      | "pre-commit" ->
          Precommit.exec sub_args;
          0
      | "--print-hooks" ->
          Info.print_hooks ();
          0
      | _ ->
          Printf.printf "unknown argument '%s'\n" cmd;
          1
    in
    exit exit_code

let exit_from_status (status : Unix.process_status) =
  let code =
    match status with
    | Unix.WEXITED code -> code
    | Unix.WSIGNALED signal -> if signal < 128 then signal + 128 else signal
    | Unix.WSTOPPED signal -> if signal < 128 then signal + 128 else signal
  in
  exit code

let print_hook_error (hook : string) (process : string)
    (status : Unix.process_status) =
  let prefix = hook ^ " hook process '" ^ process ^ "'"
  and msg =
    match status with
    | Unix.WEXITED code -> Printf.sprintf "exited with non-zero code '%d'" code
    | Unix.WSIGNALED signal ->
        Printf.sprintf "was killed by signal %s" (Sys.signal_to_string signal)
    | Unix.WSTOPPED signal ->
        Printf.sprintf "was stopped by signal %s" (Sys.signal_to_string signal)
  in
  Printf.fprintf stderr "HOOK ERROR: %s %s" prefix msg

let exec_hook (hook_name : string) =
  Log.info "executing hook '%s'" hook_name;
  let args = Array.sub Sys.argv 1 (Array.length Sys.argv - 1) in
  try
    Hooks.run hook_name args;
    Log.info "%s hook execution completed successfully" hook_name
  with Hooks.ExecError { process_status = status; process_name = process } ->
    Log.error "hook exited with non-zero code: %s" process;
    print_hook_error hook_name process status;
    exit_from_status status

(* Entrypoint *)
let () =
  Config.init ();
  let hook_name = parse_hook_name () in
  match hook_name with
  (* In this case ggh was called as 'ggh', meaning we should parse the CLI args *)
  | "ggh" -> parse_command ()
  (* The program was executed under a different name *)
  | _ -> exec_hook hook_name
