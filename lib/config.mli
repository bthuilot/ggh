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

val get_hooks : string -> string list
(** [get_hooks] returns the list of process names to start for the given hook.
*)
