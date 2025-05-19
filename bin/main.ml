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
let hook_name () : string =
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
      | "install" ->
          Install.link_hooks sub_args;
          0
      | "configure" ->
          Install.configure sub_args;
          0
      | "pre-commit" ->
          Precommit.exec sub_args;
          0
      | _ ->
          Printf.printf "unknown argument '%s'\n" cmd;
          1
    in
    exit exit_code

(* Entrypoint *)
let () =
  Config.init ();
  let hook = hook_name () in
  match hook with
  (* In this case ggh was called as 'ggh', meaning we should parse the CLI args *)
  | "ggh" -> parse_command ()
  (* The program was executed under a different name *)
  | githook -> (
      Log.info "executing hook '%s'" githook;
      let args = Array.sub Sys.argv 1 (Array.length Sys.argv - 1) in
      match Hooks.run_hooks githook args with
      | Ok _ -> Log.info "hook returned success"
      | Error (s, c) ->
          Log.info "hook returned error: %s" s;
          exit c)
