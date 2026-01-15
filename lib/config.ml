(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log

exception ValidationError of string

type trust_mode = Whitelist of string list | Blacklist of string list | All

type state = {
  mutable log_channel : out_channel;
  mutable log_level : Log.log_level;
  mutable additional_hooks : string list;
  mutable trust : trust_mode;
}
(** [state] represents the configuration of the ggh program *)

(** [t] represents the current state of the config. The values of [t] are parsed
    and populated after calling [init] *)
let t =
  {
    log_channel = stderr;
    log_level = Log.INFO;
    additional_hooks = [];
    trust = All;
  }

(** [get_additional_hook_paths] returns a list of directories that user has
    configured to additionally be called for the current hook. It should be
    thought of as additional 'core.hooksPath'. NOTE: [init] should be called
    before accessing *)
let get_additional_hook_paths () : string list = t.additional_hooks

(** [format_trust_mode] will format the current [trust_mode] into a string for
    printing and/or logging. NOTE: [init] should be called before accessing *)
let get_trust_mode () : trust_mode = t.trust

(** [all_hooks] is the list of supported hooks for ggh *)
let all_hooks =
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

(** [create_log_channel] creates the out_channel to be used for the logger. Will
    create the file "ggh.log" in either the temporary directory or the directory
    the environment value "XDG_CACHE_HOME" points to, if set *)
let create_log_channel () : out_channel =
  let log_dir =
    Utils.get_env ~default:(Filename.get_temp_dir_name ()) "XDG_CACHE_HOME"
  in
  Out_channel.open_gen
    [ Out_channel.Open_creat; Out_channel.Open_append ]
    0o600 (log_dir ^ "/ggh.log")

(** [parse_log_level] will return the desired log level from the environment and
    falls back to git config value. If nothing is defined it uses [Log.INFO] *)
let parse_log_level () : Log.log_level =
  let config_level =
    try Git.get_config_values "logLevel" |> List.hd
    with Failure _ | Git.ExecError _ -> "info"
  in
  let level = Utils.get_env ~default:config_level "GGH_LOG_LEVEL" in
  match String.lowercase_ascii level with
  | "debug" -> Log.DEBUG
  | "info" -> Log.INFO
  | "warn" -> Log.WARN
  | "error" -> Log.ERROR
  | _ ->
      Log.warn "unknown log level, ignoring";
      Log.INFO

(** [parse_log_channel ()] will parse the [out_channel] for logs to be written
    to. By default logs will be written to the log file created by
    [create_log_channel], unless the user sets the git config value
    'ggh.useStderr' or the enviornment variable "GGH_USE_STDERR" to a non-empty
    string *)
let parse_log_channel () : out_channel =
  let config_use_stderr =
    try Git.get_config_values "useStderr" |> List.hd
    with Failure _ | Git.ExecError _ -> ""
  in
  let use_stderr =
    Utils.get_env ~default:config_use_stderr "GGH_USE_STDERR" != ""
  in
  if use_stderr then (
    if Unix.isatty Unix.stderr then Log.color_on ();
    stderr)
  else create_log_channel ()

(** [format_trust_mode mode] will format the current [trust_mode] into a string
    for printing and/or logging. NOTE: [init] should be called before accessing
*)
let format_trust_mode (mode : trust_mode) =
  let format_dirs =
    List.fold_left
      (fun acc dir -> (if acc == "" then "" else acc ^ ", ") ^ dir)
      ""
  in
  match mode with
  | Whitelist dirs -> "whitelist=[" ^ format_dirs dirs ^ "]"
  | Blacklist dirs -> "blacklist=[" ^ format_dirs dirs ^ "]"
  | All -> "all"

(** [filter_relative_paths paths] will filter [paths], removing any path that is
    relative or implict (i.e. only absolute paths) *)
let filter_realtive_paths (paths : string list) =
  List.filter
    (fun p ->
      if Filename.is_relative p || Filename.is_implicit p then (
        Log.warn "ignoring realtive trust path %s" p;
        false)
      else true)
    paths

let parse_trust_mode () : trust_mode =
  let trust_mode =
    try Git.get_config_values "trustMode" |> List.hd
    with Failure _ | Git.ExecError _ -> "all"
  and parse mode =
    match String.lowercase_ascii mode with
    | "whitelist" ->
        Whitelist
          (Git.get_config_values "whitelistedPath" |> filter_realtive_paths)
    | "blacklist" ->
        Blacklist
          (Git.get_config_values "blacklistedPath" |> filter_realtive_paths)
    | "all" -> All
    | _ ->
        Log.warn "unknown trust mode, defaulting to all";
        All
  in
  try parse trust_mode
  with Git.ExecError e ->
    Log.warn "unable to parse trust mode '%s', defaulting to all: %s" trust_mode
      e;
    All

(** [parse_hooks hook_name] returns the paths to the user defined binaries to
    execute for the git hook [hook_name]. *)
let parse_hooks (hook_name : string) : string list =
  if List.mem hook_name all_hooks |> not then
    raise (ValidationError ("invalid hook name '" ^ hook_name ^ "'"));
  try Git.get_config_values hook_name
  with Git.ExecError e ->
    Log.warn "unable to retrieve hooks for '%s': %s" hook_name e;
    []

let parse_additional_hook_paths () : string list =
  try Git.get_config_values "additionalHooksPath"
  with Git.ExecError e ->
    Log.warn "Unable to parse additional hook paths from git: %s" e;
    []

(** [init_logger] will initialize the global logger to use the values specified
    in [t] *)
let init_logger () =
  begin
    Log.set_log_level t.log_level;
    Log.set_output t.log_channel
  end

(** [init] will initialize the configuration for the current process including
    the configuring the global logger and setting trust mode and additional
    hooks path. It should be called on application startup, before any other
    functions from [Config] are called *)
let init () =
  let log_level = parse_log_level ()
  and log_channel = parse_log_channel ()
  and additional_hook_paths = parse_additional_hook_paths ()
  and trust = parse_trust_mode () in
  begin
    t.log_level <- log_level;
    t.log_channel <- log_channel;
    t.additional_hooks <- additional_hook_paths;
    t.trust <- trust;
    init_logger ()
  end
