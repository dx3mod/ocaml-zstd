(lang dune 3.6)

(name zstd)

(version 0.5)

(implicit_transitive_deps false)

(generate_opam_files true)

(source
 (github ygrek/ocaml-zstd))

(authors "ygrek <ygrek@autistici.org>")

(maintainers "ygrek <ygrek@autistici.org>" "Mikhail Lopatin <dx3mod@bk.ru>")

(license BSD-3-Clause)

(package
 (name zstd)
 (synopsis "Bindings to zstd compression library")
 (description
  "Zstd, short for Zstandard, is a fast lossless compression algorithm,\ntargeting real-time compression scenarios at zlib-level compression ratio.\nSee http://zstd.net/ for more info.")
 (depends
  (ocaml
   (>= 4.14.0))
  dune-configurator
  bstr
  conf-zstd
  (alcotest :with-test))
 (tags (clib:zstd)))
