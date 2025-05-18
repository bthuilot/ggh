(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Git = Ggh.Git
module Log = Dolog.Log

(** [default_hooks_dir] is the directory that the global hooks will live if not
    provided by the user (see [get_hooks_dir]). each item in the directory
    should be a system link to the binary ggh. *)
let default_hooks_dir = "/usr/local/bin/ggh-hooks"

(** [hooks] is the list of supported hooks for ggh *)
let hooks =
  [
    "pre-commit";
    "commit-msg";
    "applypatch-msg";
    "post-update";
    "pre-merge-commit";
    "pre-receive";
    "update";
    "pre-applypatch";
    "pre-push";
    "prepare-commit-msg";
    "fsmonitor-watchman";
    "pre-rebase";
    "push-to-checkout";
    "post-commit";
  ]

(** [get_hooks_dir] will return the hooks directory where the symlinked hook
    executables are located. This value defaults to [default_hooks_dir] unless
    overrwritten with the environment variable "GGH_HOOKS_DIR" *)
let get_hooks_dir =
  try Sys.getenv "GGH_HOOKS_DIR"
  with Not_found ->
    Log.info "defaulting to hooks directory %s" default_hooks_dir;
    default_hooks_dir

exception ValidationError of string

(** [validate_hooks_dir] will validate that all hooks are symlinked to the
    current running binary in the directory returned from [get_hooks_dir]. If
    any are not valid, a [ValidationError] is raised. *)
let validate_hooks_dir (dir : string) =
  let current_bin = Sys.argv.(0) in
  List.iter
    (fun h ->
      try
        let l = Unix.readlink (dir ^ "/" ^ h) in
        if l <> current_bin then
          raise
            (ValidationError
               ("hook " ^ h ^ " does not system link to current binary "
              ^ current_bin))
      with Unix.Unix_error (_, _, _) ->
        raise (ValidationError ("unable to read link for hook " ^ h)))
    hooks

(** [help] prints the CLI help menu *)
let help () =
  print_endline "Usage: ggh [COMMAND] [OPTIONS...]\n";
  print_endline "Commands:";
  print_endline
    ("  install            Installs this executable to hooks path '"
   ^ get_hooks_dir ^ "' (should run as sudo)");
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
    under the directory returned from [get_hooks_dir]. *)
let install (_ : string array) =
  print_endline
    "NOTE: installion will require sudo, please exit and re-run as a \
     priviledged user if not alread";
  let hooks_dir = get_hooks_dir in
  if not (Sys.file_exists hooks_dir) then Sys.mkdir hooks_dir 0o755;
  if not (Sys.is_directory hooks_dir) then
    ValidationError "file exists where hooks directory should be" |> raise;
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
  (try validate_hooks_dir get_hooks_dir
   with ValidationError s ->
     print_endline ("unable to validate hooks installation: " ^ s);
     exit 1);
  Git.set_config_value ~scope:Git.Global ~group:"core" "hooksPath" get_hooks_dir

(** [print_env_opts] prints the environment variables that can be set to
    configure the application. *)
let print_env_opts (_ : string array) =
  print_endline "Environment variable options:\n";
  print_endline
    "  GGH_HOOK_OVERRIDE        Overrides hook name read from Sys.argv.(0)";
  print_endline
    "  GGH_USER_STDERR          Uses STDERR for logging rather than log file";
  print_endline "  GGH_LOG_LEVEL            Override log level read from config"
