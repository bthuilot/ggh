(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log

exception ExecError of string
(** [ExecError] represents an error executing the git binary. *)

let ( >>= ) = Option.bind
let ( % ) = Fun.compose

(** [scope] represents the file scope to use when interacting with git config,
    see https://git-scm.com/docs/git-config#FILES *)
type scope = Global | Local | System | Worktree | Command

let trusted_scopes = [ Global; System; Command ]

type config_value = scope * string
(** [config_value] represents a value returned for a key from the git config
    command. It has a [scope] and a value *)

(** [scope_to_flag] converts the [scope] into its CLI flag for git. *)
let scope_to_flag : scope -> string = function
  | Global -> "--global"
  | Local -> "--local"
  | System -> "--system"
  | Worktree -> "--workdir"
  | Command -> ""

(** [scope_to_string] converts the [scope] into its human readable name *)
let scope_to_string : scope -> string = function
  | Global -> "global"
  | Local -> "local"
  | System -> "system"
  | Worktree -> "workdir"
  | Command -> "command"

(** [scope_to_string] converts a string into a [scope] from git standard out
    when the flag '--show-scope' is specified in git config. An invalid scope
    will result in a [ExecError] *)
let scope_from_string : string -> scope = function
  | "global" -> Global
  | "local" -> Local
  | "system" -> System
  | "worktree" -> Worktree
  | "command" -> Command
  | s -> raise @@ ExecError ("git returned value from unknown scope" ^ s)

(** [exec_git_command] will run a git command in a shell and return the standard
    output. If there is an issue running the command, an [ExecError] will be
    raised. *)
let exec_git_command ?(valid_exit_codes : int list = [ 0 ]) (cmd : string) :
    string =
  let stdout = Unix.open_process_in cmd in
  let value = In_channel.input_all stdout in
  match Unix.close_process_in stdout with
  | Unix.WEXITED n ->
      if List.mem n valid_exit_codes then String.trim value
      else raise @@ ExecError (Printf.sprintf "git exited with code %d" n)
  | _ -> raise @@ ExecError "git killed by signal"

(** [parse_config_output] parses the output from git config to a list of
    [config_value]. *)
let parse_config_output (output : string) : config_value list =
  if String.equal output "" then []
  else
    let parse_line = function
      | [ s; v ] -> (
          try Some (scope_from_string s, v)
          with ExecError _ ->
            Log.warn "ignoring invalid scope value %s" s;
            None)
      | _ ->
          Log.warn "unable to parse git config output value, skipping";
          None
    and lines = String.split_on_char '\n' output |> List.rev in
    List.filter_map (parse_line % String.split_on_char '\t' % String.trim) lines

(** [get_config_values] returns all the values associated with the key. The
    config values will be read from all scopes and if 'scopes' is specified to
    be Some list of [scope], then only the values from those scopes will be
    returned. By default, scopes is set to [trusted_scopes]. *)
let get_config_values ?(scopes : scope list option = Some trusted_scopes)
    ?(group : string = "ggh") (name : string) : string list =
  let cmd =
    "git config get --show-scope --includes --all '" ^ group ^ "." ^ name ^ "'"
  and filter_scopes (scope, value) =
    match scopes with
    | None -> Some value
    | Some s -> if List.mem scope s then Some value else None
  in
  let _ = Log.debug "executing git command: %s" cmd in
  exec_git_command ~valid_exit_codes:[ 0; 1 ] cmd
  |> parse_config_output
  |> List.filter_map filter_scopes

(** [set_config_value] will write the config value to the respective git config
    file for the given scope. By defualt git will write to the [Local] config
    file. See https://git-scm.com/docs/git-config#FILES *)
let set_config_value ?(valid_exit_codes : int list = [ 0 ])
    ?(scope : scope = Local) ?(group : string = "ggh") (name : string)
    (value : string) =
  let full_name = group ^ "." ^ name and flag = scope_to_flag scope in
  let scopeArgs = if flag = "" then [||] else [| flag |] in
  let args =
    Array.concat [ [| "git"; "config" |]; scopeArgs; [| full_name; value |] ]
  in
  let pid = Unix.create_process "git" args Unix.stdin Unix.stdout Unix.stderr in
  let _, status = Unix.waitpid [] pid in
  match status with
  | Unix.WEXITED code ->
      if List.mem code valid_exit_codes then ()
      else
        failwith
          "unable to write config value; git process finished with non 0 exit \
           code"
  | _ -> failwith "unable to write config value; git process killed"

(** [get_dir] gets the current git repository directory (i.e. .git, or root when
    cloned using --mirror. *)
let get_dir () : string =
  let cmd = "git rev-parse --git-dir" in
  exec_git_command cmd |> Filename.concat (Unix.getcwd ())
