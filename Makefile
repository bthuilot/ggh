# Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.


LIBSOURCEDIR := ./lib
BINSOURCEDIR := ./bin
BUILDDIR := ./_build
DUNELOCKSOURCEDIR := ./dune.lock

# OPAM configuration
OPAM := opam
OPAMSWITCH ?= $(CURDIR)
OCAML_VERSION ?= 5.1.0
OPAMDIR := $(OPAMSWITCH)/_opam
OPAMFILE := ggh.opam
OPAMEXEC := $(OPAM) exec --switch $(OPAMSWITCH) --

BIN := "$(BUILDDIR)/default/bin/main.exe"

LIBSOURCES := $(shell find $(LIBSOURCEDIR) -name "*.ml" -or -name "*.mli" -or -name "dune")
BINSOURCES := $(shell find $(BINSOURCEDIR) -name "*.ml" -or -name "*.mli" -or -name "dune")
DUNESOURCES := ./dune-project $(shell find $(DUNELOCKSOURCEDIR) -name "*.pkg" -or -name "*.dune")
OPAMSOURCES := $(OPAMFILE)
OPAMARGS ?= --with-test --with-doc --with-dev-setup 

DESTDIR ?=
SYSTEMPREFIX ?= $(DESTDIR)/usr/local
SYSTEMBIN ?= $(SYSTEMPREFIX)/bin/ggh

$(OPAMDIR)/.opam-switch/switch-config:
	$(OPAM) switch create $(OPAMSWITCH) $(OCAML_VERSION) --no-install
	$(MAKE) install-deps

.PHONY: install-deps
install-deps: switch
	$(OPAM) install --switch $(OPAMSWITCH) . --yes --deps-only $(OPAMARGS)

.PHONY: switch
switch: $(OPAMDIR)/.opam-switch/switch-config

GGHCOMMITSHA ?= $(shell git describe --no-match --always --abbrev=10 --dirty)
BUILDARGS ?= 
export GGHCOMMITSHA
$(BIN): switch $(LIBSOURCES) $(BINSOURCES) $(DUNESOURCES) $(OPAMSOURCES)
	@$(OPAMEXEC) dune build $(BUILDARGS)

.PHONY: build
build: $(BIN)

.PHONY: utop
utop: switch
	@$(OPAMEXEC) utop

.PHONY: pkg-lock
pkg-lock: switch
	@$(OPAMEXEC) dune pkg lock

.PHONY: test
test: switch
	@$(OPAMEXEC) dune test

.PHONY: lint
lint: switch
	@$(OPAMEXEC) dune fmt --preview

.PHONY: lint-fix
lint-fix: switch
	@$(OPAMEXEC) dune fmt

.PHONY: clean
clean: switch
	@$(OPAMEXEC) dune clean

.PHONY: cleanup-switch
cleanup-switch:
	@$(OPAM) switch remove $(OPAMSWITCH) --yes 2>/dev/null || true

HOOKSPREFIX ?= /usr/share
HOOKSDIR ?= $(DESTDIR)$(HOOKSPREFIX)/ggh/hooks

$(HOOKSDIR):
	mkdir -p $(HOOKSDIR)

.PHONY: install
install: $(HOOKSDIR)
	@install -Dm 755 -T $(BIN) $(SYSTEMBIN)
	@$(BIN) print-hooks | while read -r hook; do \
		ln -sf $(SYSTEMBIN) $(HOOKSDIR)/$$hook; done
	@echo "GGH installed, to use please your hooks path to the following: "
	@echo '$$ git config set --global core.hooksPath $(HOOKSDIR)'


.PHONY: install-default-hooks
install-default-hooks:
	@install -Dm755 -T hooks/ggh-gitleaks.sh $(SYSTEMPREFIX)/bin/ggh-gitleaks
	@install -Dm755 -T hooks/ggh-conventional-commit.sh $(SYSTEMPREFIX)/bin/ggh-conventional-commit
	@install -Dm755 -T hooks/ggh-signed-off.sh $(SYSTEMPREFIX)/bin/ggh-signed-off

