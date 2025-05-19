(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Config = Ggh.Config

(** [help] prints the CLI help menu *)
let help () =
  print_endline "Usage: ggh [COMMAND] [OPTIONS...]\n";
  print_endline "Commands:";
  print_endline
    ("  install            Installs this executable to hooks path '"
   ^ Config.get_hooks_dir ^ "' (should run as sudo)");
  print_endline
    "  configure          Sets the 'core.hooksPath' in the global git \
     configuration (should run after 'install' as user)";
  print_endline "  pre-commit         Pre-commit integrations";
  print_endline "  print-opts         Prints the environment variable options";
  print_endline "";
  print_endline "Options:";
  print_endline "  --version          Print version information and exit.";
  print_endline "  --help             Print this help message and exit.";
  print_endline "";
  print_endline "Environment variable options:";
  print_endline
    "  GGH_HOOK_OVERRIDE        Overrides hook name read from Sys.argv.(0)";
  print_endline
    "  GGH_USE_STDERR          Uses STDERR for logging rather than log file";
  print_endline "  GGH_LOG_LEVEL            Override log level read from config";
  print_endline "  GGH_HOOKS_DIR            Override the ggh hooks directory"

let version () =
  print_endline ("version: " ^ Metadata.version);
  print_endline ("commit: " ^ Metadata.commit)
