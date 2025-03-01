(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log

(** [get_env] returns the value of an environment variable, or [default] if not
    set. *)
let get_env ?(default : string = "") (var : string) =
  try Sys.getenv var with Not_found -> default

(** [log_channel] creates the out_channel to be used for the logger. Will create
    the file "[base_dir]/[folder]/main.log" *)
let log_channel () : out_channel =
  let log_dir =
    get_env ~default:(Filename.get_temp_dir_name ()) "XDG_CACHE_HOME"
  in
  Out_channel.open_gen
    [ Out_channel.Open_creat; Out_channel.Open_append ]
    0o600 (log_dir ^ "/ggh.log")

(** [parse_log_level] will return the desired log level from the environment and
    falls back to git config value. If nothing is defined it uses [Log.INFO] *)
let parse_log_level () : Log.log_level =
  let lvl =
    get_env
      ~default:
        (match Git.get_config_value "log-level" with
        | None -> "info"
        | Some (_, l) -> l)
      "GGH_LOG_LEVEL"
  in
  match String.lowercase_ascii lvl with
  | "debug" -> Log.DEBUG
  | "info" -> Log.INFO
  | "warn" -> Log.WARN
  | "error" -> Log.ERROR
  | _ ->
      Log.warn "unknown log level, ignoring";
      Log.INFO

(** [init_logger] will initialize the global logger. Will set the level and the
    output channel. The output channel will be either $HOME/.ggh/main.log if
    $HOME is set, or /$TMPDIR/ggh/main.log if TMPDIR is set. If $GGH_USER_STDERR
    is set, output will be written to STDERR. *)
let init_logger ?(lvl = Log.INFO) () =
  Log.set_log_level lvl;
  try
    let _ = Sys.getenv "GGH_USE_STDERR" in
    if Unix.isatty Unix.stderr then Log.color_on ();
    Log.set_output stderr;
    Log.debug "using STDERR for logs"
  with Not_found -> log_channel () |> Log.set_output

(** [init] initiations the configuration of the application *)
let init () =
  let log_level = parse_log_level () in
  init_logger ~lvl:log_level ()

let is_trusted_scope = function
  | Git.Global -> true
  | Git.System -> true
  | _ -> false

let get_whitelisted_dirs () : string list =
  let global =
    Git.get_config_values ~scope:Git.Global "trusted-dirs"
    |> Option.value ~default:[]
  and system =
    Git.get_config_values ~scope:Git.Global "trusted-dirs"
    |> Option.value ~default:[]
  in
  List.map (fun (_, v) -> v) (global @ system)

let get_user_trust_mode () : string option =
  let global_trust = Git.get_config_value ~scope:Git.Global "trust-mode"
  and system_trust = Git.get_config_value ~scope:Git.System "trust-mode" in
  match global_trust with
  | Some (_, v) -> Some v
  | _ -> ( match system_trust with Some (_, v) -> Some v | _ -> None)

(* TODO(bryce): these should be refactored to just return string lists,
   filtering out the [Git.values] that dont come from a trusted scope. *)

(** [get_hooks] returns the paths to the user defined binaries to execute for
    the given hook name. *)
let get_hooks (hook_name : string) =
  match Git.get_config_values hook_name with Some hooks -> hooks | None -> []

let get_recursive_hooks () : Git.value list =
  match Git.get_config_values "recursive-paths" with
  | Some paths -> paths
  | None -> []
