(** Zstandard (zstd) compression and decompression.

    Zstandard is a fast, lossless compression algorithm developed by Facebook.
    This library provides OCaml bindings to the reference C implementation. *)

module Compressor = Compressor
module Decompressor = Decompressor
module Dictionary = Dictionary
module Io_buffer = Io_buffer
module Bindings = Bindings
