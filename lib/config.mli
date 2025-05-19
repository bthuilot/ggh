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

val get_recursive_hooks : unit -> Git.value list
(** [get_recursive_hooks] returns a list of directories that user has configured
    to additionally be called for the current hook. I should be thought of a sub
    'core.hooksPath' *)

exception ValidationError of string

val validate_hooks_dir : string -> unit
(** [validate_hooks_dir] will validate that all hooks are symlinked to the
    current running binary in the directory returned from [get_hooks_dir]. If
    any are not valid, a [ValidationError] is raised. *)

val all_hooks : string list
(** [all_hooks] is a list of all supported git hooks *)

val default_hooks_dir : string
(** [default_hooks_dir] is the directory that the global hooks will live if not
    provided by the user (see [get_hooks_dir]). each item in the directory
    should be a system link to the binary ggh. *)

val get_hooks_dir : string
(** [get_hooks_dir] will return the hooks directory where the symlinked hook
    executables are located. This value defaults to [default_hooks_dir] unless
    overrwritten with the environment variable "GGH_HOOKS_DIR" *)
