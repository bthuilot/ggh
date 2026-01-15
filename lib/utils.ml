(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

(* strings *)

(** [trim_suffix] trims a suffix from a string if exists *)
let trim_suffix (suffix : string) (s : string) =
  let l = String.length s - String.length suffix in
  if String.ends_with ~suffix s then String.sub s 0 l else s

(** [trim_prefix] trims a prefix from a string if exists *)
let trim_prefix (prefix : string) (s : string) =
  let l = String.length s - String.length prefix in
  if String.starts_with ~prefix s then String.sub s (String.length prefix) l
  else s

(* environment *)

(** [get_env] returns the value of an environment variable, or [default] if not
    set. *)
let get_env ?(default : string = "") (var : string) =
  try Sys.getenv var with Not_found -> default

(* files *)

exception PathError of string

(** [assert_abs_path] will assert a path is absolute and raise [PathError] if
    not *)
let assert_abs_path (path : string) : string =
  if Filename.is_implicit path || Filename.is_relative path then
    raise (PathError "relative path not expected")
  else path

(** [is_subpath] with check if the first argument is a subpath of the second.
    Both paths must by absolute, and a [PathError] will be raise if either are
    not *)
let is_subpath (child : string) (parent : string) : bool =
  String.starts_with ~prefix:(assert_abs_path parent) (assert_abs_path child)

(** [join_paths] will join to paths using [Filename.dir_sep] *)
let join_paths (parent : string) (child : string) : string =
  let sep = Filename.dir_sep in
  String.concat sep [ trim_suffix sep parent; trim_prefix sep child ]
