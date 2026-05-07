# Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

LIBSOURCEDIR := $(shell pwd)/lib
BINSOURCEDIR := $(shell pwd)/bin
BUILDDIR := $(shell pwd)/_build
DUNEPROJECT := $(shell pwd)/dune-project
DUNELOCKSOURCEDIR := $(shell pwd)/dune.lock

# OPAM configuration
OPAM := opam
OPAMSWITCH ?= $(CURDIR)
OCAML_VERSION ?= 5.1.0
OPAMDIR := $(OPAMSWITCH)/_opam
OPAMFILE := ggh.opam
OPAMEXEC := $(OPAM) exec --switch $(OPAMSWITCH) --

LIBSOURCES := $(shell find $(LIBSOURCEDIR) -name "*.ml" -or -name "*.mli" -or -name "dune")
BINSOURCES := $(shell find $(BINSOURCEDIR) -name "*.ml" -or -name "*.mli" -or -name "dune")
DUNESOURCES := $(DUNEPROJECT) $(shell find $(DUNELOCKSOURCEDIR) -name "*.pkg" -or -name "*.dune")
OPAMSOURCES := $(OPAMFILE)
OPAMARGS ?= --with-test --with-doc --with-dev-setup 

DESTDIR ?=
SYSTEMPREFIX ?= $(DESTDIR)/usr/local
SYSTEMBIN ?= $(SYSTEMPREFIX)/bin/ggh

BIN := "$(BUILDDIR)/default/bin/main.exe"
BUILDARGS ?=
GGHCOMMITSHA ?= $(shell git describe --no-match --always --abbrev=10 --dirty)
export GGHCOMMITSHA

DUNE_VERSION_LINE := ^\(version
GGH_VERSION ?= v$(shell grep -E '$(DUNE_VERSION_LINE)' dune-project | cut -c 10- | sed 's/.$$//' )
IMG ?= ghcr.io/bthuilot/ggh:$(GGH_VERSION)

$(BIN): switch $(LIBSOURCES) $(BINSOURCES) $(DUNESOURCES) $(OPAMSOURCES)
	@$(OPAMEXEC) dune build $(BUILDARGS)

.PHONY: build
build: $(BIN)

DOCKER_ARGS ?=
.PHONY: docker-build
docker-build:
	@echo "building docker image with tag '$(IMG)'"
	@docker build \
		--build-arg GGHCOMMITSHA=$(GGHCOMMITSHA) \
		--tag $(IMG) \
		$(DOCKER_ARGS) \
		-f Dockerfile .


$(OPAMDIR)/.opam-switch/switch-config:
	$(OPAM) switch create $(OPAMSWITCH) $(OCAML_VERSION) --no-install
	$(MAKE) install-deps

.PHONY: install-deps
install-deps: switch
	$(OPAM) install --switch $(OPAMSWITCH) . --yes --deps-only $(OPAMARGS)

.PHONY: switch
switch: $(OPAMDIR)/.opam-switch/switch-config

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
	@"$(LICENSE_EYE)" header check

.PHONY: lint-fix
lint-fix: switch
	@$(OPAMEXEC) dune fmt
	@"$(LICENSE_EYE)" header fix

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

##@ Dev Tools

LOCALBIN ?= $(BUILDDIR)/bin
$(LOCALBIN):
	mkdir -p "$(LOCALBIN)"

## Tool Binaries
LICENSE_EYE ?= $(LOCALBIN)/license-eye
RATCHET ?= $(LOCALBIN)/ratchet

## Tool Versions
LICENSE_EYE_VERSION ?= v0.0.0-20260505070609-e910f72bae86
RATCHET_VERSION ?= v0.11.4

license-eye: $(LICENSE_EYE) ## Download license-eyes locally if necessary.
$(LICENSE_EYE): $(LOCALBIN)
	$(call go-install-tool,$(LICENSE_EYE),github.com/apache/skywalking-eyes/cmd/license-eye,$(LICENSE_EYE_VERSION))


ratchet: $(RATCHET) ## Download ratchet locally if necessary.
$(RATCHET): $(LOCALBIN)
	$(call go-install-tool,$(RATCHET),github.com/sethvargo/ratchet,$(RATCHET_VERSION))


# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f "$(1)-$(3)" ] && [ "$$(readlink -- "$(1)" 2>/dev/null)" = "$(1)-$(3)" ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
rm -f "$(1)" ;\
GOBIN="$(LOCALBIN)" go install $${package} ;\
mv "$(LOCALBIN)/$$(basename "$(1)")" "$(1)-$(3)" ;\
} ;\
ln -sf "$$(realpath "$(1)-$(3)")" "$(1)"
endef

define gomodver
$(shell go list -m -f '{{if .Replace}}{{.Replace.Version}}{{else}}{{.Version}}{{end}}' $(1) 2>/dev/null)
endef
