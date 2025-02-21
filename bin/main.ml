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
let hook_name () : string option =
  try
    let hook = Sys.getenv "GGH_HOOK_OVERRIDE" in
    Log.warn "hook overriden from enviroment";
    Some hook
  with Not_found ->
    let bin = Sys.argv.(0) |> Filename.basename in
    if bin = "ggh" then None else Some bin

(** [parse_args] will parse the arguments for the program. This is supposed to
    be called when the program is run as 'ggh' and not a git hook *)
let parse_args () =
  let n_args = Array.length Sys.argv in
  if n_args < 2 then (
    Printf.printf "please provide an argument\n";
    exit 1)
  else
    let cmd = Sys.argv.(1) in
    match cmd with
    | "--help" ->
        Commands.help ();
        exit 0
    | "install" ->
        Commands.install (Array.sub Sys.argv 1 (n_args - 1));
        exit 0
    | "configure" ->
        Commands.configure (Array.sub Sys.argv 1 (n_args - 1));
        exit 0
    | _ ->
        Printf.printf "unknown argument '%s'\n" cmd;
        exit 1

(* Entrypoint *)
let () =
  Config.init ();
  let hook = hook_name () in
  match hook with
  (* In this case ggh was called as 'ggh', meaning we should parse the CLI args *)
  | None -> parse_args ()
  (* The program was executed under a different name *)
  | Some hook -> (
      Log.info "executing hook '%s'" hook;
      let args = Array.sub Sys.argv 1 (Array.length Sys.argv - 1) in
      match Hooks.run_hooks hook args with
      | Ok _ -> Log.info "hook returned success"
      | Error (s, c) ->
          Log.info "hook returned error: %s" s;
          exit c)
