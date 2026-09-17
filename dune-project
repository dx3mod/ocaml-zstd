(lang dune 3.6)

(name ozstd)

(version 0.1)

(implicit_transitive_deps false)

(generate_opam_files true)

(source
 (github dx3mod/ozstd))

(authors "Mikhail Lopatin <dx3mod@bk.ru>")

(maintainers "Mikhail Lopatin <dx3mod@bk.ru>")

(license MIT)

(package
 (name ozstd)
 (synopsis "A thin, modern OCaml binding to Zstandard")
 (description
  "A thin and modern OCaml binding to the Zstandard compression library. It provides common one-shot and streaming APIs from the reference C implementation, exposing them through a small and idiomatic interface.")
 (depends
  (ocaml
   (>= 5.5.0))
  dune-configurator
  bstr
  conf-zstd
  (alcotest :with-test))
 (tags (clib:zstd)))
