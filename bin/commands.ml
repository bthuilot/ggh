module Git = Ggh.Git
module Log = Dolog.Log

(** [help] prints the CLI help menu *)
let help () =
  print_endline "Usage: ggh [COMMAND] [OPTIONS...]\n";
  print_endline "Commands:";
  print_endline "  install            Installs this executable as the global git config";
  print_endline "  print-opts         Prints the environment variable options";
  print_endline "";
  print_endline "Options:";
  (* print_endline "  --version          Print version information and exit."; *)
  print_endline "  --help             Print this help message and exit."


(** [hooks_dir] is the directory that the global hooks will live.Arith_status
    each item in the directory should be a system link to the binary ggh.
*)
let hooks_dir = "/usr/local/bin/_ggh"

(** [hooks] is the list of supported hooks for ggh *)
let hooks = [
  "pre-commit";
  "commit-msg";
  "pre-push";
]
  

(** [install] installs the current running binary as the core hooks path
    in the users gitconfig by first system linking it self as each
    hook in [hooks] under the directory  [hooks_dir], then setting [hooks_dir]
    as the core hook paths *)
let install (_: string array) =
  if not (Sys.is_directory hooks_dir) then  Sys.mkdir hooks_dir 0o755 ;
  let bin_path = Unix.realpath Sys.argv.(0) in
  List.iter
    (fun h ->
       let sym_link = (hooks_dir ^ "/" ^ h) in
       if Sys.file_exists sym_link then
         begin
           Log.info "removing old file at %s" sym_link;
           Sys.remove sym_link
         end;
       Unix.symlink bin_path sym_link
    )
    hooks

let configure (_: string array) =
  Git.set_config_value ~global:true ~group:"core" "hooksPath" hooks_dir