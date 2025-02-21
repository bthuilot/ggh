(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

module Log = Dolog.Log

(** [get_repository_hooks] returns the current git directory's hook for the
    given hook name. *)
let get_repository_hooks (hook_name : string) : string list =
  match Git.get_dir () with
  | None -> []
  | Some dir ->
      if dir ^ "/" ^ hook_name |> Sys.file_exists then [ dir ^ "/" ^ hook_name ]
      else []

(** [exec_hook] will execute a hook and return a result with [Ok] being a
    [Unix.process_status] if the execution was started successfully or an
    [Error] that has a description of the error. with [hook_name] set as the
    first argument with [args] passed as the rest. This is done so that the
    called process can know what hook is being executed (i.e. pre-commit vs
    commit-msg vs pre-push). *)
let exec_hook (hook_name : string) (hook_path : string) (args : string array) :
    (Unix.process_status, string) result =
  try
    let pid =
      Unix.create_process hook_path
        (Array.append [| hook_name |] args)
        Unix.stdin Unix.stdout Unix.stderr
    in
    let _, status = Unix.waitpid [] pid in
    Ok status
  with Unix.Unix_error (e, _, _) -> Error (Unix.error_message e)

(** [run_hooks] will run all hooks for the given hook name. It will find the
    processes to execute by looking at the values set for the hook name is the
    'ggh' gitconfig in scope [Git.All]. Additionally it will execute the hooks
    confiured in the repository's hook folder in the git directory. *)
let run_hooks (hook_name : string) (args : string array) :
    (unit, string * int) result =
  let rec user_hooks = Config.get_hooks hook_name
  and repo_hooks = get_repository_hooks hook_name
  and exec_all : string list -> (unit, string * int) result = function
    | [] -> Ok ()
    | h :: hs -> (
        Log.debug "executing %s" h;
        match exec_hook hook_name h args with
        | Ok (Unix.WEXITED 0) -> exec_all hs
        | Ok (Unix.WEXITED code) ->
            Error
              (Printf.sprintf "hook '%s' failed with exit code %d" h code, code)
        | Ok (Unix.WSIGNALED signal) ->
            Error
              ( Printf.sprintf "hook '%s' kill by signal %d" h signal,
                signal + 128 )
        | Ok (Unix.WSTOPPED signal) ->
            Error
              ( Printf.sprintf "hook '%s' stopped by signal %d" h signal,
                signal + 128 )
        | Error s ->
            Log.warn "failed to start process '%s': %s" h s;
            exec_all hs)
  in
  exec_all (user_hooks @ repo_hooks)
