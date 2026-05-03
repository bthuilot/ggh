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

type policy_action =
  | Confirm
  | Deny
  | Allow
      (** [policy] represnets the policy for a local git hook execution. It can
          either be [Confirm] meaning prompt the user for confirmation before
          executing, [Deny] meaning do not execute or [Allow] meaning execute **)

val init : unit -> unit
(** [init] will initialize the configuration for the current process including
    the configuring the global logger and setting trust mode and additional
    hooks path. It should be called on application startup, before any other
    functions from [Config] are called *)

val all_hooks : string list
(** [all_hooks] is a list of all supported git hooks *)

val policy_for_dir : string -> policy_action
(** [policy_for_dir] will return the [policy_action] that should be used when
    executing the local git hooks for a repository with the root at the given
    directory *)

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
