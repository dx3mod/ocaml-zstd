(** Zstandard (zstd) compression and decompression library.

    Zstandard is a fast, lossless compression algorithm developed by Facebook.
    This library provides OCaml bindings to the reference C implementation. *)

(** {2 Compression and decompression} *)

module Compressor = Compressor
module Decompressor = Decompressor

(** {2 Miscellaneous} *)

module Dictionary = Dictionary

(** Returns the version of the linked libzstd C library as a triple
    [(major, minor, patch)].*)
let version () =
  let v = Bindings.version () in
  (v / 10_000, v / 100 mod 100, v mod 100)

(** {2 Internals} *)

module Bindings_intf = Bindings
