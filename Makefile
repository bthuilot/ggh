# Copyright (C) 2025 Bryce Thuilot <bryce@thuilot.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.


LIBSOURCEDIR = ./lib
BINSOURCEDIR = ./bin
DUNELOCKSOURCEDIR = ./dune.lock

LIBSOURCES := $(shell find $(LIBSOURCEDIR) -name "*.ml" -or -name "*.mli" -or -name "dune")
BINSOURCES := $(shell find $(BINSOURCEDIR) -name "*.ml" -or -name "*.mli" -or -name "dune")
DUNESOURCES := ./dune-project $(shell find $(DUNELOCKSOURCEDIR) -name "*.pkg" -or -name "*.dune")
OPAMSOURCES := ./ggh.opam


BIN := "_build/default/bin/main.exe"

SYSTEM_BIN := /usr/local/bin/ggh
XDG_DATA_HOME ?= ${HOME}/.local/share
USER_HOOKS_PATH := ${XDG_DATA_HOME}/ggh

.PHONY: install-deps 
install-deps:
	@opam install . --deps-only

.PHONY: install-all-deps
install-all-deps:
	@opam install . --deps-only --with-test --with-doc

$(BIN): $(LIBSOURCES) $(BINSOURCES) $(DUNESOURCES) $(OPAMSOURCES)
	@opam exec -- dune build

.PHONY: build
build: $(BIN)

.PHONY: lint
lint:
	@opam exec -- dune fmt --preview

.PHONY: lint-fix
lint-fix:
	@opam exec -- dune fmt

.PHONY: install
install:
	@if ! [ "$(shell id -u)" = 0 ]; then echo "this command must be run using sudo"; exit 1; fi
	@install -T -C $(BIN) $(SYSTEM_BIN)

.PHONY: install-default-hooks
install-default-hooks:
	@if ! [ "$(shell id -u)" = 0 ]; then echo "this command must be run using sudo";  exit 1; fi
	@install -T -C hooks/ggh-gitleaks.sh /usr/local/bin/ggh-gitleaks
	@install -T -C hooks/ggh-conventional-commit.sh /usr/local/bin/ggh-conventional-commit
	@install -T -C hooks/ggh-signed-off.sh /usr/local/bin/ggh-signed-off

configure: $(BIN)
	@echo "creating directory $(USER_HOOKS_PATH) and symbolic links"
	@mkdir -p $(USER_HOOKS_PATH)
	@GGH_HOOK_OVERRIDE=ggh $(BIN) --print-hooks | while read -r hook; do ln -s $(SYSTEM_BIN) $(USER_HOOKS_PATH)/$$hook; done
	@echo "setting 'core.hooksPath' for global git config to $(USER_HOOKS_PATH)"
	@git config set --global core.hooksPath $(USER_HOOKS_PATH)
	@echo "please run 'sudo make install' to complete installation"

