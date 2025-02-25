(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log

let ( >>= ) = Option.bind

(** [scope] represents the file scope to use when interacting with git config,
    see https://git-scm.com/docs/git-config#FILES *)
type scope = Any | Global | Local | System | Worktree | Command

type value = scope * string

(** [scope_to_flag] converts the [scope] into its CLI flag for git. *)
let scope_to_flag : scope -> string = function
  | Global -> "--global"
  | Local -> "--local"
  | System -> "--system"
  | Worktree -> "--workdir"
  | Command -> ""
  | Any -> ""

let scope_to_string : scope -> string = function
  | Global -> "global"
  | Local -> "local"
  | System -> "system"
  | Worktree -> "workdir"
  | Command -> "command"
  | Any -> "any"

let scope_from_string : string -> scope option = function
  | "global" -> Some Global
  | "local" -> Some Local
  | "system" -> Some System
  | "worktree" -> Some Worktree
  | "command" -> Some Command
  | _ -> None

let config_value ?(scope : scope = Any) ?(all : bool = false)
    ?(group : string = "ggh") (name : string) : string option =
  let stdout =
    Unix.open_process_in
      ("git config get --show-scope --includes " ^ scope_to_flag scope ^ " "
      ^ (if all then "--all" else "")
      ^ " '" ^ group ^ "." ^ name ^ "'")
  in
  let value = In_channel.input_all stdout in
  match Unix.close_process_in stdout with
  | Unix.WEXITED 0 -> Some (String.trim value)
  | _ -> None

let parse_value (line : string) : value option =
  let split = String.split_on_char '\t' (String.trim line) in
  List.nth_opt split 0 >>= scope_from_string >>= fun s ->
  List.nth_opt split (List.length split - 1) >>= fun v -> Some (s, v)

(** [get_config_value] returns the config value from the git config command *)
let get_config_value ?(scope : scope = Any) ?(group : string = "ggh")
    (name : string) : value option =
  config_value ~scope ~all:false ~group name >>= parse_value

(** [get_config_values] returns all the config value from the git config
    command. *)
let get_config_values ?(scope : scope = Any) ?(group : string = "ggh")
    (name : string) : value list option =
  config_value ~scope ~all:true ~group name >>= fun output ->
  let rec lines = String.split_on_char '\n' output
  and parse_lines acc = function
    | [] -> Some acc
    | l :: ls -> parse_value l >>= fun v -> parse_lines (v :: acc) ls
  in
  parse_lines [] lines

(** [set_config_value] will write the config value to the respective git config
    file for the given scope. If scope is [Any], git will write to the [Local]
    config file. See https://git-scm.com/docs/git-config#FILES *)
let set_config_value ?(scope : scope = Any) ?(group : string = "ggh")
    (name : string) (value : string) =
  let full_name = group ^ "." ^ name and flag = scope_to_flag scope in
  let scopeArgs = if flag = "" then [||] else [| flag |] in
  let args =
    Array.concat [ [| "git"; "config" |]; scopeArgs; [| full_name; value |] ]
  in
  let pid = Unix.create_process "git" args Unix.stdin Unix.stdout Unix.stderr in
  let _, status = Unix.waitpid [] pid in
  match status with
  | Unix.WEXITED 0 -> ()
  | _ ->
      failwith "unable to write config value; git process finished with non 0"

(** [get_dir] gets the current git repository directory. *)
let get_dir () =
  let stdout = Unix.open_process_in "git rev-parse --show-toplevel" in
  let dir = In_channel.input_all stdout in
  match Unix.close_process_in stdout with
  | Unix.WEXITED 0 -> Some (String.trim dir)
  | _ -> None
