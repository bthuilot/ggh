# Global Git Hooks

A system-wide git hook configuration for easy, consitant, and personalized configuration.

## Overview

Global git hooks provides a way to run various git hooks across your whole system.
While other tools like [pre-commit](https://pre-commit.com/) are designed with collaboration and config sharing in mind,
ggh is not. Easily add personalized hooks to your development enviroment across all your
git repositories and aditionally provide projection against running untrusted git hooks.

### Sample hooks

ggh ships with 3 pre-defined hooks currently, located in the `hooks` directory

1. `ggh-gitleaks`: runs gitleaks as a pre-commit hook, exiting 1 if a secret is found (requires gitleaks to be installed)
2. `ggh-conventional-commit`: A commit-msg hook to ensure the message meets the convetional commit standard
3. `ggh-signed-off`: a commit-msg hook to ensure the message includes a `Signed-off-by` block.

These programs are optional and can be installed along side `ggh` via `make install-default-hooks`

## Installation

Currently installation is only supported by building the program and installing from a clone.
You will require [Opam](https://opam.ocaml.org/) to build/compile yourself

```bash
git clone https://github.com/bthuilot/ggh
cd ggh/

make

# 'make install' will install the binary
# to /usr/local/bin/ggh and system-link
# the binary to $HOME/.local/share/ggh/${HOOK_NAME}
# for each git hook ggh supports.
# It will then configure GGH for all git hooks
# by editing the user's global git config
sudo make install

## OPTIONAL ##
# Install the "Sample hooks" listed above
# to /usr/bin/local/
sudo make install-default-hooks 
```

## Homebrew install 

If you have [homebrew](https://brew.sh) installed,
you can install via:

```bash
brew tap bthuilot/tap

brew install bthuilot/tap/ggh
```

## Configuration

All configuration for ggh is done using the `.gitconfig` file
and via the `git config` command. All options should be prefixed by `ggh.`
section of your config. Below are the list of options.

| Config key                                          | Description                                                            | Mutliple values?                                                                                                                                                                                                   |
|-----------------------------------------------------|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `$HOOK_NAME` (e.g `pre-commit`, `commit-msg`, etc.) | The hooks to execute when the respective hook (`$HOOK_NAME`) is called | yes                                                                                                                                                                                                                |
| `additionalHooksPath`                               | Additional hooks path to call when executed                            | yes                                                                                                                                                                                                                |
| `logLevel`                                          | The log level for ggh                                                  | no                                                                                                                                                                                                                 |
| `defaultPolicyAction`                                      | no                                                                     | The policy of a git directory local hooks when not specified.                                                                                                                                              |
| `allow`                                             | yes                                                                    | Mark the local hooks in a directory as allowed. If the base of the path is a wildcard (e.g. `/dir/*`) this indicates that directory and all sub directories.                                                       |
| `deny`                                             | yes                                                                    | Mark the local hooks in a directory as blocked and will not be run. If the base of the path is a wildcard (e.g. `/dir/*`) this indicates that directory and all sub directories.                                   |
| `confirm`                                               | yes                                                                    | Specify that before running a local hook in the directory, the user should be asked for confirmation. If the base of the path is a wildcard (e.g. `/dir/*`) this indicates that directory and all sub directories. |




You can also manually edit the gitconfig manually

```gitconfig
# ~/.gitconfig
[ggh]
	## Hooks ##
   	# set pre-commit hooks #
	pre-commit = gitleaks 

	# commit-msg hooks #
	commit-msg = ggh-signed-off
	commit-msg = ggh-conventional-commit
	## Application config ##

	## GGH Config ##
	logLevel = debug
	
	# Additional hooks path to call
	additionalHooksPath = /other/hooks/path/to/call
	
	## Local hook policy ##
	
	# Set the default policy action for
	# executing local repository hooks when
	# a policy is not specified for the directory
	defaultPolicyAction = deny # can be: allow, deny, confirm
	
	# specify policy per directory.
	# A wildcard '*' can be specified at the end to indicate
	# sub directories as well.
	# If a path is matched in mutliple policies,
	# precedence is as follows:
	# - if matched in a 'deny', do not run directory hooks
	# - if matched in an 'confirm', prompt user before executing
	# - if matched in an 'allow', run the directory hooks
	# - use default policy action
	allow = /home/user/projects/*
	allow = /home/user/work/*
	confirm = /home/user/*
```


## Integration with [pre-commit](https://pre-commit.com/)

Integrating with pre-commit configs shouldn't be affected and should work automtically.
However, when installing pre-commit hooks, pre-commit currently exits if the `core.hooksPath`
is set (which `ggh` relies on). To get around this, the following command 

```bash
ggh pre-commit install
```

This will run `pre-commit install` but set the environment variable `GIT_CONFIG=/dev/null` 
(meaning run without reading the users gitconfig)
