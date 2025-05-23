# global git hooks

A system-wide git hook configuration for easy, consitant, and personalized configuration.

## Overview

Global git hooks provides a way to run various git hooks across your whole system.
While other tools like [pre-commit](https://pre-commit.com/) are designed with collaboration and config sharing in mind,
ggh is not. Easily add personalized hooks to your development enviroment across all your
git repositories.

### Sample hooks

ggh ships with 3 pre-defined hooks currently, located in the `hooks` directory

1. `ggh-gitleaks`: runs gitleaks as a pre-commit hook, exiting 1 if a secret is found (requires gitleaks to be installed)
2. `ggh-conventional-commit`: A commit-msg hook to ensure the message meets the convetional commit standard
3. `ggh-signed-off`: a commit-msg hook to ensure the message includes a `Signed-off-by` block.

The are installed along side `ggh` via `make install`

## Installation

Currently installation is only supported by building the program and installing from a clone

```bash
git clone https://github.com/bthuilot/ggh
cd ggh/
make install # will use sudo to install
# will move binaries to /usr/local/bin and configure 'core.hooks' gitconfig value
```

## Configuration

All configuration for ggh is done using the `.gitconfig` file
and via the `git config` command. All options should be prefixed by `ggh.`
section of your config. Below are the list of options

| Config key                                          | Description                                                            | Mutliple values? |
|-----------------------------------------------------|------------------------------------------------------------------------|------------------|
| `$HOOK_NAME` (e.g `pre-commit`, `commit-msg`, etc.) | The hooks to execute when the respective hook (`$HOOK_NAME`) is called | yes              |
| `additionalHooksPath`                               | Additional hooks path to call when executed                            | yes              |
| `logLevel`                                          | The log level for ggh                                                  | no               |


You can also manually edit the gitconfig manually

```gitconfig
# ~/.gitconfig
[ggh]
	## Application config ##

	# global config #
	# log level of GGH
	logLevel = debug
	
	# additional hooks path to call
	# on each hook
	additionalHooksPath = /other/hooks/path/to/call
	
	## Hooks ##
	
	# pre-commit hooks #
	pre-commit = ggh-gitleaks

	# commit-msg hooks #
	commit-msg = ggh-signed-off
	commit-msg = ggh-conventional-commit
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
