(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Git = Ggh.Git
module Hooks = Ggh.Hooks
module Log = Dolog.Log
module Config = Ggh.Config

(** [link_hooks] links the current running binary as each of the supported git
    hooks inside of the directory returned from [get_hooks_dir] *)
let link_hooks (_ : string array) =
  print_endline
    "NOTE: installion will require sudo, please exit and re-run as a \
     priviledged user if not alread";
  let hooks_dir = Config.get_hooks_dir in
  if not (Sys.file_exists hooks_dir) then Sys.mkdir hooks_dir 0o755;
  if not (Sys.is_directory hooks_dir) then
    Config.ValidationError "file exists where hooks directory should be"
    |> raise;
  let bin_path = Unix.realpath Sys.argv.(0) in
  List.iter
    (fun h ->
      let sym_link = hooks_dir ^ "/" ^ h in
      if Sys.file_exists sym_link then (
        Log.info "removing old file at %s" sym_link;
        Sys.remove sym_link);
      Unix.symlink bin_path sym_link)
    Config.all_hooks

(** [configure] configures the global git config setting the 'core.hooksPath'
    value to the directory [hooks_dir]. This should be ran after [install] to
    ensure the dirrectory is correctly set up. *)
let configure (_ : string array) =
  (try Config.validate_hooks_dir Config.get_hooks_dir
   with Config.ValidationError s ->
     print_endline ("unable to validate hooks installation: " ^ s);
     exit 1);
  Git.set_config_value ~scope:Git.Global ~group:"core" "hooksPath"
    Config.get_hooks_dir
