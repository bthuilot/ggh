(** [get_config_value] returns the config value from the git config command *)
let get_config_value ?(global : bool = true) ?(all : bool = false)
    ?(group : string = "ggh") (name : string) =
  let stdout =
    Unix.open_process_in
      ("git config get --includes "
      ^ (if global then "--global" else "")
      ^ " "
      ^ (if all then "--all" else "")
      ^ " '" ^ group ^ "." ^ name ^ "'")
  in
  let value = In_channel.input_all stdout in
  match Unix.close_process_in stdout with
  | Unix.WEXITED 0 -> Some (String.trim value)
  | _ -> None

(** [get_config_values] returns all the config value from the git config command
*)
let get_config_values ?(global : bool = true) (name : string) =
  match get_config_value ~global ~all:true name with
  | Some result -> Some (String.split_on_char '\n' result)
  | None -> None

let set_config_value ?(global : bool = true) ?(group : string = "ggh")
    (name : string) (value : string) =
  let full_name = group ^ "." ^ name in
  let args =
    if global then [| "git"; "config"; "--global"; full_name; value |]
    else [| "git"; "config"; full_name; value |]
  in
  let pid = Unix.create_process "git" args Unix.stdin Unix.stdout Unix.stderr in
  let _, status = Unix.waitpid [] pid in
  match status with
  | Unix.WEXITED 0 -> ()
  | _ ->
      failwith "unable to write config value; git process finished with non 0"

let get_dir () =
  let stdout = Unix.open_process_in "git rev-parse --show-toplevel" in
  let dir = In_channel.input_all stdout in
  match Unix.close_process_in stdout with
  | Unix.WEXITED 0 -> Some (String.trim dir)
  | _ -> None
