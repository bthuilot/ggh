# Copyright (C) 2025 Bryce Thuilot <bryce@thuilot.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

SYSTEM_BIN := /usr/local/bin/ggh
BIN := "_build/default/bin/main.exe"
HOOKS_PATH := /usr/local/ggh/

export GGH_VERSION ?= $(shell git describe --tags --always --dirty)
export GGH_COMMIT ?= $(shell git rev-parse --short HEAD)


.PHONY: install-deps install-all-deps build install
install-deps:
	@opam install . --deps-only

install-all-deps:
	@opam install . --deps-only --with-test --with-doc

print-version:
	@echo "version: ${GGH_VERSION}"
	@echo "commit: ${GGH_COMMIT}"

build: install-deps
	@dune build

fmt:
	@dune fmt

lint:
	@dune fmt --preview

install:
	@dune build
	@echo "sudo is needed for install and will be used"
	@sudo cp -a ${BIN} ${SYSTEM_BIN}
	@sudo mkdir -p ${HOOKS_PATH}
	@GGH_LOG_LEVEL=debug GGH_USE_STDERR=1 sudo -E ${SYSTEM_BIN} install
	@GGH_LOG_LEVEL=debug GGH_USE_STDERR=1 ${SYSTEM_BIN} configure
	@sudo cp -p hooks/ggh-gitleaks.sh /usr/local/bin/ggh-gitleaks
	@sudo cp -p hooks/ggh-conventional-commit.sh /usr/local/bin/ggh-conventional-commit
	@sudo cp -p hooks/ggh-signed-off.sh /usr/local/bin/ggh-signed-off

