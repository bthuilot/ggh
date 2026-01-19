# _G_lobal _G_it _H_ooks

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

The are installed along side `ggh` via `make install`

## Installation

Currently installation is only supported by building the program and installing from a clone.
You will require [Opam](https://opam.ocaml.org/) to build/compile yourself

```bash
git clone https://github.com/bthuilot/ggh
cd ggh/

make configure # will build application and configure git config's `core.hooksPath`
sudo make install # will move binaries to /usr/local/bin 

# Optional #
sudo make install-default-hooks # will install the "Sample hooks" listed above
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

| Config key                                          | Description                                                                                                                                                                                                | Mutliple values? |
|-----------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------|
| `$HOOK_NAME` (e.g `pre-commit`, `commit-msg`, etc.) | The hooks to execute when the respective hook (`$HOOK_NAME`) is called                                                                                                                                     | yes              |
| `additionalHooksPath`                               | Additional hooks path to call when executed                                                                                                                                                                | yes              |
| `logLevel`                                          | The log level for ggh                                                                                                                                                                                      | no               |
| `trustMode`                                         | The trust mode for GGH to determine which local repository hooks to run.  either `all` (meaning run all hooks, ignore trust), `whitelist` (see `whitelistPath` below) or `blacklist` (blacklist path below | no               |
| `whitelistedPath`                                   | If the trust mode is `whitelist`, GGH will only run repository hooks that are children of at least one path that is set.                                                                                   | yes              |
| `blacklistedPath`                                   | If the trust mode is `blacklist`, GGH will run repository hooks unless the path is a child of one of the blacklisted paths.                                                                                | yes              |



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
	
	## Trust ##
	
	# meaning only run repo hook
	# if a child path of one of the
	# whitelisted paths
	
	trustMode = whitelist
	
	whitelistedPath = /home/user/projects
	whitelistedPath = /home/user/oss
	
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
