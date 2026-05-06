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
