(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)
module Log = Dolog.Log

type mode = Allow | Ask | Block

let ( >>= ) = Option.bind

let match_dir (dir : string) (pattern : string) : bool =
  if String.ends_with ~suffix:"*" pattern then
    let parent = Utils.trim_suffix "*" pattern in
    String.starts_with
      ~prefix:(Utils.trim_suffix "/" parent)
      (Utils.trim_suffix "/" dir)
  else Utils.trim_suffix "/" dir = Utils.trim_suffix "/" pattern

let is_trusted (dir : string) : bool =
  let dirs = Config.get_whitelisted_dirs () in
  match List.find_opt (match_dir dir) dirs with None -> false | Some _ -> true

let parse_mode (m : string) : mode =
  match String.lowercase_ascii m with
  | "ask" -> Ask
  | "allow" -> Allow
  | "block" -> Block
  | _ -> raise (Invalid_argument "invalid trust mode")

let get_trust_mode () : mode =
  Config.get_user_trust_mode ()
  >>= (fun t -> Some (parse_mode t))
  |> Option.value ~default:Block
