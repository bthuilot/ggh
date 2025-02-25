(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

let trim_suffix (suffix : string) (s : string) =
  let l = String.length s - String.length suffix in
  if String.ends_with ~suffix s then String.sub s 0 l else s

let trim_prefix (prefix : string) (s : string) =
  let l = String.length s - String.length prefix in
  if String.starts_with ~prefix s then String.sub s (String.length prefix) l
  else s
