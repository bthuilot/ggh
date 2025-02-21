(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

(** [scope] represents the file scope to use when interacting with git config,
    see https://git-scm.com/docs/git-config#FILES *)
type scope = All | Global | Local | System | Workdir

(** [scope_to_flag] converts the [scope] into its CLI flag for git. *)
let scope_to_flag : scope -> string = function
  | Global -> "--global"
  | Local -> "--local"
  | System -> "--system"
  | Workdir -> "--workdir"
  | All -> ""

(** [get_config_value] returns the config value from the git config command *)
let get_config_value ?(scope : scope = All) ?(all : bool = false)
    ?(group : string = "ggh") (name : string) =
  let stdout =
    Unix.open_process_in
      ("git config get --includes " ^ scope_to_flag scope ^ " "
      ^ (if all then "--all" else "")
      ^ " '" ^ group ^ "." ^ name ^ "'")
  in
  let value = In_channel.input_all stdout in
  match Unix.close_process_in stdout with
  | Unix.WEXITED 0 -> Some (String.trim value)
  | _ -> None

(** [get_config_values] returns all the config value from the git config
    command. *)
let get_config_values ?(scope : scope = All) (name : string) =
  match get_config_value ~scope ~all:true name with
  | Some result -> Some (String.split_on_char '\n' result)
  | None -> None

(** [set_config_value] will write the config value to the respective git config
    file for the given scope. If scope is [All], git will write to the [Local]
    config file. See https://git-scm.com/docs/git-config#FILES *)
let set_config_value ?(scope : scope = All) ?(group : string = "ggh")
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
