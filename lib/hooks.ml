(*
 * Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log
module StringSet = Set.Make (String)

exception
  ExecError of { process_name : string; process_status : Unix.process_status }
(** [ExecError] is an exception that is raised when a hook process is executed
    by doesn't complete successfully *)

(** [exec_hooks] will exec each process in the given list. The process will be
    given the arguments passed to ggh program and additionally the first
    argument (i.e. the name of the invoked process) will be set to the name of
    the hook being executed. *)
let exec_hooks (processes : string list) (hook_name : string)
    (args : string array) =
  let process_args = Array.append [| hook_name |] args in
  let exec process_name =
    try
      Log.debug "executing %s hook '%s'" hook_name process_name;
      let pid =
        Unix.create_process process_name process_args Unix.stdin Unix.stdout
          Unix.stderr
      in
      let _, status = Unix.waitpid [] pid in
      Ok status
    with Unix.Unix_error (e, _, _) -> Error (Unix.error_message e)
  in
  let rec iter_exec = function
    | [] -> ()
    | process :: processes' -> (
        match exec process with
        | Ok (Unix.WEXITED 0) -> iter_exec processes'
        | Ok status ->
            let err =
              ExecError { process_status = status; process_name = process }
            in
            raise err
        | Error s ->
            Log.warn "skipping %s hook process '%s, failed to start: %s"
              hook_name process s;
            iter_exec processes')
  in
  iter_exec processes

(** [get_additional_hooks] will find additional hooks that should be executed
    based on the user definied additional hook paths. See
    [Config.get_additional_hook_paths] *)
let get_additional_hooks (hook_name : string) : string list =
  Config.get_additional_hook_paths ()
  |> List.map (fun v -> Utils.trim_suffix "/" v ^ "/" ^ hook_name)
  |> List.filter Sys.file_exists

let allow_hook_directory (hook_name : string) (dir : string) : bool =
  let action = Config.policy_for_dir dir in
  match action with
  | Config.Allow -> true
  | Config.Deny -> false
  | Config.Confirm ->
      Tty.confirm
        ("execute " ^ hook_name ^ " hook for repository '" ^ dir ^ "'?")

(** [get_repository_hooks] returns the current git directory's hook for the
    given hook name. i.e. .git/hooks/$NAME where $NAME is the hook name *)
let get_repository_hooks (hook_name : string) : string list =
  let hook_path = Git.get_dir () ^ "/hooks/" ^ hook_name
  and root = Git.get_root () in
  if not (Sys.file_exists hook_path) then
    let () = Log.debug "no local hook found for %s" hook_path in
    []
  else if not (allow_hook_directory hook_name root) then
    let () = Log.warn "hook execution for '%s' denied" hook_path in
    []
  else [ hook_path ]
(* TODO(bryce):
   additionally read ggh configs from local *)

(** [run] will run all hooks for the given hook name. It will get all the hooks
    configured for the git config value 'ggh.$HOOK_NAME' where '$HOOK_NAME' is
    the name of the hook passed to the function (see [Config.parse_hooks].
    Additionally, it will find any additionally configured hook paths and
    execute the file with the same name as the hook in that path (see
    [Config.get_additional_hook_paths]. Lastly it will look for the hook in the
    local repository path [Git.get_dir] and if trusted, will execute that local
    hook as well. *)
let run (hook_name : string) (args : string array) =
  let () = Log.info "retrieving hooks configured via ggh"
  and ggh_hooks = Config.parse_hooks hook_name
  and () = Log.info "retrieving additional hook paths"
  and additional_hook_paths = get_additional_hooks hook_name
  and () = Log.info "retrieving repo level hooks"
  and repo_hooks = get_repository_hooks hook_name in
  let all_hooks =
    List.flatten [ ggh_hooks; additional_hook_paths; repo_hooks ]
  in
  exec_hooks all_hooks hook_name args
