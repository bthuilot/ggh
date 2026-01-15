module Log = Dolog.Log

exception GitFailure of string

let write_repo_config (key : string) (value : string) : unit =
  let cmd = "git config set " ^ key ^ " " ^ value in
  match Sys.command cmd with
  | 0 -> ()
  | _ -> raise (GitFailure "unable to write repo config")

let write_global_config (key : string) (value : string) : unit =
  let cmd = "git config set --global " ^ key ^ " " ^ value in
  match Sys.command cmd with
  | 0 -> ()
  | _ -> raise (GitFailure "unable to write global config")

let print_repo_config ?(all : bool = false) (key : string) : unit =
  let cmd = "git config get " ^ (if all then " --all " else "") ^ key in
  match Sys.command cmd with
  | 0 -> ()
  | _ -> raise (GitFailure "unable to read repo config")

let print_global_config ?(all : bool = false) (key : string) : unit =
  let cmd =
    "git config get --global " ^ (if all then " --all " else "") ^ key
  in
  match Sys.command cmd with
  | 0 -> ()
  | _ -> raise (GitFailure "unable to read repo config")

let clear_values (keys : string list) : unit =
  List.map (fun k -> (k, Sys.command ("git config --unset-all " ^ k))) keys
  |> List.iter (function
    | _, 0 -> ()
    | k, _ -> raise (GitFailure ("failed to remove key " ^ k)))
