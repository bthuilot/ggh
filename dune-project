(lang dune 3.17)

(name ggh)
(version 0.3.0)

(generate_opam_files true)

(source
 (github bthuilot/ggh))

(authors "Bryce Thuilot <bryce@thuilot.io>")

(maintainers "Bryce Thuilot <bryce@thuilot.io>")

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
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat :with-dev-setup)
  (utop :with-dev-setup)
  (merlin :with-dev-setup))
 (tags
  (git sdlc pre-commit supply-chain)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
