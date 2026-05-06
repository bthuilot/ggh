(*
 * Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the FSF, either version 3 of the License, or (at your option) any later version.
 * See the LICENSE file in the root of this repository for full license text or
 * visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
 *)

module Log = Dolog.Log

exception ValidationError of string

type policy_action = Confirm | Deny | Allow

let parse_policy_action = function
  | "confirm" -> Confirm
  | "deny" -> Deny
  | "allow" -> Allow
  | _ -> raise (ValidationError "unkown policy")

type hook_policies = {
  default_action : policy_action;
  confirm : string list;
  deny : string list;
  allow : string list;
}

type state = {
  mutable log_channel : out_channel;
  mutable log_level : Log.log_level;
  mutable additional_hooks : string list;
  mutable hook_policies : hook_policies;
}
(** [state] represents the configuration of the ggh program *)

(** [t] represents the current state of the config. The values of [t] are parsed
    and populated after calling [init] *)
let t =
  {
    log_channel = stderr;
    log_level = Log.INFO;
    additional_hooks = [];
    hook_policies =
      { default_action = Confirm; confirm = []; deny = []; allow = [] };
  }

(** [get_additional_hook_paths] returns a list of directories that user has
    configured to additionally be called for the current hook. It should be
    thought of as additional 'core.hooksPath'. NOTE: [init] should be called
    before accessing *)
let get_additional_hook_paths () : string list = t.additional_hooks

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

(** [filter_relative_paths paths] will filter [paths], removing any path that is
    relative or implict (i.e. only absolute paths) *)
let filter_realtive_paths (paths : string list) =
  List.filter
    (fun p ->
      if Filename.is_relative p || Filename.is_implicit p then (
        Log.warn "ignoring realtive repository path '%s'" p;
        false)
      else true)
    paths

(** [parse_hook_policies] will parse the [hook_policies] specified by the user
    in their git config *)
let parse_hook_policies () : hook_policies =
  {
    default_action =
      (try
         parse_policy_action
           (Git.get_config_values "defaultPolicyAction" |> List.hd)
       with Failure _ | Git.ExecError _ | ValidationError _ ->
         Log.info "unable to parse default policy action, defaulting to confirm";
         Confirm);
    confirm = Git.get_config_values "confirm" |> filter_realtive_paths;
    deny = Git.get_config_values "deny" |> filter_realtive_paths;
    allow = Git.get_config_values "allow" |> filter_realtive_paths;
  }

(** [parse_hooks hook_name] returns the paths to the user defined binaries to
    execute for the git hook [hook_name]. *)
let parse_hooks (hook_name : string) : string list =
  if List.mem hook_name all_hooks |> not then
    raise (ValidationError ("invalid hook name '" ^ hook_name ^ "'"));
  try Git.get_config_values hook_name
  with Git.ExecError e ->
    Log.warn "unable to retrieve hooks for '%s': %s" hook_name e;
    []

(** [policy_contains_dir] will return true if the list of directories for a
    policy contains the given directory, meaning that policy should be applied
    to the this directory *)
let policy_contains_dir (policy : string list) (dir : string) : bool =
  let dir_matches (pattern : string) : bool =
    if String.ends_with ~suffix:"*" pattern then (
      let prefix = String.sub pattern 0 (String.length pattern - 1) in
      Log.info "comparing %s with %s" prefix dir;
      String.starts_with ~prefix dir)
    else (
      Log.info "testing %s and %s" pattern dir;
      String.equal pattern dir)
  in
  List.exists dir_matches policy

let policy_for_dir (dir : string) : policy_action =
  if policy_contains_dir t.hook_policies.deny dir then Deny
  else if policy_contains_dir t.hook_policies.confirm dir then Confirm
  else if policy_contains_dir t.hook_policies.allow dir then Allow
  else t.hook_policies.default_action

let parse_additional_hook_paths () : string list =
  try Git.get_config_values "additionalHooksPath"
  with Git.ExecError e ->
    Log.warn "Unable to parse additional hook paths from git: %s" e;
    []

(** [init_logger] will initialize the global logger to use the values specified
    in [t] *)
let init_logger () =
  Log.set_log_level t.log_level;
  Log.set_output t.log_channel

(** [init] will initialize the configuration for the current process including
    the configuring the global logger and setting trust mode and additional
    hooks path. It should be called on application startup, before any other
    functions from [Config] are called *)
let init () =
  t.log_level <- parse_log_level ();
  t.log_channel <- parse_log_channel ();
  init_logger ();
  t.additional_hooks <- parse_additional_hook_paths ();
  t.hook_policies <- parse_hook_policies ()
