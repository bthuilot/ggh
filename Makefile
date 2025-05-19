SYSTEM_BIN := /usr/local/bin/ggh
BIN := "_build/default/bin/main.exe"
HOOKS_PATH := /usr/local/ggh/

.PHONY: install-deps install-all-deps build install
install-deps:
	@opam install . --deps-only

install-all-deps:
	@opam install . --deps-only --with-test --with-doc

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
	@sudo cp -p hooks/ggh-gitleaks /usr/local/bin/ggh-gitleaks
	@sudo cp -p hooks/ggh-conventional-commit /usr/local/bin/ggh-conventional-commit
	@sudo cp -p hooks/ggh-signed-off /usr/local/bin/ggh-signed-off

