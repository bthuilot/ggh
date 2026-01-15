(*
 * Copyright (C) 2025 bryce thuilot <bryce@thuilot.io>
 *
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see LICENSE file located
 * in the root of the repository.
 *)

exception ValidationError of string
(** [ValidationError] is an exception thrown when functions in are given invalid
    or malformed values from the user. The error will contain a message
    describing the issue *)

type trust_mode = Whitelist of string list | Blacklist of string list | All

val init : unit -> unit
(** [init] will initialize the configuration for the current process including
    the configuring the global logger and setting trust mode and additional
    hooks path. It should be called on application startup, before any other
    functions from [Config] are called *)

val all_hooks : string list
(** [all_hooks] is a list of all supported git hooks *)

val get_trust_mode : unit -> trust_mode
(** [get_trust_mode] returns the [trust_mode] for the currrent program *)

val format_trust_mode : trust_mode -> string
(** [format_trust_mode] will format the current [trust_mode] into a string for
    printing and/or logging. NOTE: [init] should be called before accessing *)

val get_additional_hook_paths : unit -> string list
(** [get_additional_hook_paths] returns a list of directories that user has
    configured to additionally be called for the current hook. It should be
    thought of as additional 'core.hooksPath'. NOTE: [init] should be called
    before accessing *)

val parse_hooks : string -> string list
(** [parse_hooks] returns the list of process names or binaries to start for the
    given hook. This is not parsed during [init] since the name of the hook
    should be parsed from the first program argument. The hook name must be one
    of [all_hooks], and a [ValidationError] will be raised if not. *)
