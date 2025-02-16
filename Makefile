SYSTEM_BIN := /usr/local/bin/ggh
BIN := "_build/default/bin/main.exe"

.PHONY: install-deps build install
install-deps:
	@opam install . --deps-only --with-test --with-doc

build: install-deps
	@dune build

install:
	@dune build
	@echo "sudo is needed for install and will be used"
	@sudo cp -a ${BIN} ${SYSTEM_BIN}
	@GGH_LOG_LEVEL=debug GGH_USE_STDERR=1 sudo -E ${SYSTEM_BIN} install
	@GGH_LOG_LEVEL=debug GGH_USE_STDERR=1 ${SYSTEM_BIN} configure
	@sudo cp -p hooks/ggh-gitleaks /usr/local/bin/ggh-gitleaks
	@sudo cp -p hooks/ggh-conventional-commit /usr/local/bin/ggh-conventional-commit
	@sudo cp -p hooks/ggh-signed-off /usr/local/bin/ggh-signed-off

