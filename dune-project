(lang dune 3.17)
; Copyright (C) 2025-2026 bryce thuilot <bryce@thuilot.io>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the FSF, either version 3 of the License, or (at your option) any later version.
; See the LICENSE file in the root of this repository for full license text or
; visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

(name ggh)
(version 0.3.0-beta.1)

(generate_opam_files true)

(source
 (github bthuilot/ggh))

(authors "bryce thuilot <bryce@thuilot.io>")

(maintainers "bryce thuilot <bryce@thuilot.io>")

(license GPL-3.0-or-later)

(documentation https://github.com/bthuilot/ggh/tree/main?tab=readme-ov-file#global-git-hooks)

(package
 (name ggh)
 (synopsis "Global git hooks")
 (description "Globally available git hooks to be run on all your git projects.")
 (depends
  (ocaml (>= 5.1.0))
   dune
  (dolog (>= 4.0.0))
  (odoc :with-doc)
  (alcotest :with-test)
  (ocamlformat :with-test)
  (ocaml-lsp-server :with-dev-setup)
  (utop :with-dev-setup)
  (merlin :with-dev-setup))
 (tags
  (git sdlc pre-commit supply-chain)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
