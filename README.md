# global git hooks

A system-wide git hook configuration for easy, consitant, and personalized configuration.

## Overview

Global git hooks provides a way to run various git hooks across your whole system.
While other tools like [pre-commit](https://pre-commit.com/) are designed with collaboration and config sharing in mind,
ggh is not. Easily add personalized hooks to your development enviroment across all your
git repositories.

### Sample hooks

ggh ships with 3 pre-defined hooks currently

1. `ggh-gitleaks`: runs gitleaks as a pre-commit hook, exiting 1 if a secret is found
2. `ggh-conventional-commit`: A commit-msg hook to ensure the message meets the convetional commit standard
3. `ggh-signed-off`: a commit-msg hook to ensure the message includes a `Signed-off-by` block.

## Installation

Currently installation is only supported by building the program and installing from a clone

```bash
git clone https://github.com/bthuilot/ggh
cd ggh/
make install # will use sudo to install
# and additionall overwrite your global 'core.hooksPath' valye
```

## Configuration

All configuration for ggh is done using the `.gitconfig` file
and via the `git config` command. All options should be prefixed by `ggh.`
section of your config. Below are the list of options

| Config key   | Description                           | Mutliple values? |
|--------------|---------------------------------------|------------------|
| `pre-commit` | Hooks to run during 'pre-commit' hook | yes              |
| `commit-msg` | Hooks to run during 'commit-msg' hook | yes              |
| `log-level`  | The log level for ggh                 | no               |

You can also manually edit the gitconfig manually

```gitconfig
# ~/.gitconfig
[ggh]
	# global config #
	log-level = debug
	
	# pre-commit hooks #
	pre-commit = ggh-gitleaks

	# commit-msg hooks #
	commit-msg = ggh-signed-off
	commit-msg = ggh-conventional-commit
```
