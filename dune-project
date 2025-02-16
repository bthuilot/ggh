(lang dune 3.12)

(name ggh)

(generate_opam_files true)

(source
 (github bthuilot/ggh))

(authors "Bryce Thuilot <bryce@thuilot.io>")

(maintainers "Bryce Thuilot <bryce@thuilot.io>")

(license GPL-3.0-or-later)

(documentation https://github.com/bthuilot/ggh/wiki)

(package
 (name ggh)
 (synopsis "global git hooks")
 (description "globally available git hooks to be run on all your git projects")
 (depends ocaml dune dolog ocamlformat)
 (tags
  (git sdlc pre-commit supply-chain)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
