(** Zstandard (zstd) compression and decompression.

    Zstandard is a fast, lossless compression algorithm developed by Facebook.
    This library provides OCaml bindings to the reference C implementation. *)

module Compressor = Compressor
module Decompressor = Decompressor
module Dictionary = Dictionary
module Io_buffer = Io_buffer

(** {2 Miscellaneous} *)

(** [version ()]

    Returns the version of the linked libzstd C library as a triple
    [(major, minor, patch)].*)
let version () =
  let v = Bindings.version () in
  (v / 10_000, v / 100 mod 100, v mod 100)

(** {2 Internals} *)

module Bindings_intf = Bindings
