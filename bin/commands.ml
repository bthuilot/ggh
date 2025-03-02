(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Git = Ggh.Git
module Log = Dolog.Log

(** [hooks_dir] is the directory that the global hooks will live.Arith_status
    each item in the directory should be a system link to the binary ggh. *)
let hooks_dir = "/usr/local/ggh"

(** [hooks] is the list of supported hooks for ggh *)
let hooks = [ "pre-commit"; "commit-msg"; "pre-push" ]

(** [help] prints the CLI help menu *)
let help () =
  print_endline "Usage: ggh [COMMAND] [OPTIONS...]\n";
  print_endline "Commands:";
  print_endline
    ("  install            Installs this executable to hooks path '" ^ hooks_dir
   ^ "' (should run as sudo)");
  print_endline
    "  configure          Sets the 'core.hooksPath' in the global git \
     configuration (should run after 'install' as user)";
  print_endline "  print-opts         Prints the environment variable options";
  print_endline "";
  print_endline "Options:";
  (* print_endline "  --version          Print version information and exit."; *)
  print_endline "  --help             Print this help message and exit."

(** [install] installs the current running binary as the core hooks path in the
    users gitconfig by first system linking it self as each hook in [hooks]
    under the directory [hooks_dir], then setting [hooks_dir] as the core hook
    paths *)
let install (_ : string array) =
  if not (Sys.is_directory hooks_dir) then Sys.mkdir hooks_dir 0o755;
  let bin_path = Unix.realpath Sys.argv.(0) in
  List.iter
    (fun h ->
      let sym_link = hooks_dir ^ "/" ^ h in
      if Sys.file_exists sym_link then (
        Log.info "removing old file at %s" sym_link;
        Sys.remove sym_link);
      Unix.symlink bin_path sym_link)
    hooks

(** [configure] configures the global git config setting the 'core.hooksPath'
    value to the directory [hooks_dir]. This should be ran after [install] to
    ensure the dirrectory is correctly set up. *)
let configure (_ : string array) =
  Git.set_config_value ~scope:Git.Global ~group:"core" "hooksPath" hooks_dir

(** [print_env_opts] prints the environment variables that can be set to
    configure the application. *)
let print_env_opts (_ : string array) =
  print_endline "Environment variable options:\n";
  print_endline
    "  GGH_HOOK_OVERRIDE        Overrides hook name read from Sys.argv.(0)";
  print_endline
    "  GGH_USER_STDERR          Uses STDERR for logging rather than log file";
  print_endline "  GGH_LOG_LEVEL            Override log level read from config"
