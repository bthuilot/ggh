(lang dune 3.17)

(name ggh)

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
  (ocamlformat :with-test)
  (alcotest :with-test))
 (tags
  (git sdlc pre-commit supply-chain)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
