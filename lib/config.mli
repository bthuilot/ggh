(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

val init : unit -> unit
(** [init] will initialize the configuration for the current process including
    the configuring the global logger. *)

val get_hooks : string -> Git.value list
(** [get_hooks] returns the list of process names to start for the given hook.
*)

val is_trusted_scope : Git.scope -> bool
(** [is_trusted_scope] returns if the current scope is trusted for Git config
    values *)

val get_whitelisted_dirs : unit -> string list
(** [get_whitelisted_dirs] returns a list of directories that are considered
    trusted *)

val get_user_trust_mode : unit -> string option
(** [get_trust_mode] returns the trust mode configured by the user. Will be
    [None] if no option was provided *)
