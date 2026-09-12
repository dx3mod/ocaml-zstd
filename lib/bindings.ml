type compression_context = external "ZSTD_CCtx"
and decompression_context = external "ZSTD_DCtx"

external create_compression_context : unit -> compression_context
  = "caml_create_zstd_cctx_s"

external create_decompression_context : unit -> decompression_context
  = "caml_create_zstd_dctx_s"

type decompression_stream = external "ZSTD_DStream"

external create_decompression_stream : unit -> decompression_stream
  = "caml_create_zstd_dstream"

type dictionary = string

external version : unit -> int = "caml_zstd_version"
external compress_bound : int -> int = "caml_zstd_compress_bound"

external compress_bigstring : Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring"

external compress_bigstring_with_context :
  compression_context -> Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring_with_context_bytecode"
    "caml_zstd_compress_bigstring_with_context"

external compress_bigstring_with_context_and_dictionary :
  compression_context ->
  dictionary ->
  Bstr.t ->
  int ->
  Bstr.t ->
  int ->
  int ->
  int
  = "caml_zstd_compress_bigstring_with_context_and_dictionary_bytecode"
    "caml_zstd_compress_bigstring_with_context_and_dictionary"

external compress_string : string -> int -> bytes -> int -> int -> int
  = "caml_zstd_compress_string"

external compress_string_with_context :
  compression_context -> string -> int -> bytes -> int -> int -> int
  = "caml_zstd_compress_string_with_context_bytecode"
    "caml_zstd_compress_string_with_context"

external compress_string_with_context_and_dictionary :
  compression_context ->
  dictionary ->
  string ->
  int ->
  bytes ->
  int ->
  int ->
  int
  = "caml_zstd_compress_string_with_context_and_dictionary_bytecode"
    "caml_zstd_compress_string_with_context_and_dictionary"

external decompress_bigstring : Bstr.t -> Bstr.t -> int -> int -> int
  = "caml_zstd_decompress_bigstring"

external decompress_bigstring_with_context :
  decompression_context -> Bstr.t -> Bstr.t -> int -> int -> int
  = "caml_zstd_decompress_bigstring_with_context"

external decompress_bigstring_with_context_and_dictionary :
  decompression_context -> dictionary -> Bstr.t -> Bstr.t -> int -> int -> int
  = "caml_zstd_decompress_bigstring_with_context_and_dictionary_bytecode"
    "caml_zstd_decompress_bigstring_with_context_and_dictionary"

external decompress_string : string -> bytes -> int -> int
  = "caml_zstd_decompress_string"

external decompress_string_with_context :
  decompression_context -> string -> bytes -> int -> int
  = "caml_zstd_decompress_string_with_context"

external decompress_string_with_context_and_dictionary :
  decompression_context -> dictionary -> string -> bytes -> int -> int
  = "caml_zstd_decompress_string_with_context_and_dictionary"

module Directive = struct
  let continue = 0
  and flush = 1
  and eend = 2
end

external compress_stream2 :
  compression_context -> Io_buffer.t -> Io_buffer.t -> int -> int * int * int
  = "caml_zstd_compress_stream2"

external decompress_stream :
  decompression_stream -> Io_buffer.t -> Io_buffer.t -> int * int * int
  = "caml_zstd_decompress_stream"
