module Log = Dolog.Log


let get_repository_hooks (hook: string) =
  match Git.get_dir () with
  | None -> []
  | Some dir ->
    if (dir ^ "/" ^ hook |> Sys.file_exists) then
      [ dir ^ "/" ^ hook; ]
    else
      []

let exec_hook
    (hook_name: string) (hook_path: string) (args: string array)
  : (Unix.process_status, string) result  =
  try
    let pid = Unix.create_process
        hook_path (Array.append [| hook_name |] args)
        Unix.stdin Unix.stdout Unix.stderr
    in let _, status = Unix.waitpid [] pid in
    Ok status
  with
  | Unix.Unix_error (e, _, _) -> Error (Unix.error_message e)


let run_hooks (hook: string) (args: string array): (unit,  (string * int)) result =
  let rec user_hooks = Config.get_hooks hook
  and repo_hooks = get_repository_hooks hook
  and exec_all : string list -> (unit, (string * int)) result = function
    | [] -> Ok ()
    | h :: hs -> Log.debug "executing %s" h; match exec_hook hook h args with
      | Ok (Unix.WEXITED 0) -> exec_all hs
      | Ok (Unix.WEXITED code) -> Error (
          (Printf.sprintf "hook '%s' failed with exit code %d" h code), code)
      | Ok (Unix.WSIGNALED signal) -> Error (
          (Printf.sprintf "hook '%s' kill by signal %d" h signal), signal + 128)
      | Ok (Unix.WSTOPPED signal) -> Error (
          (Printf.sprintf "hook '%s' stopped by signal %d" h signal), signal + 128)
      | Error s -> Log.warn "failed to start process '%s': %s" h s; exec_all hs
  in 
  exec_all (user_hooks @ repo_hooks)
