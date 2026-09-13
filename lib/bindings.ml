type compression_context = external "ZSTD_CCtx"
and decompression_context = external "ZSTD_DCtx"

external create_compression_context : unit -> compression_context
  = "caml_create_zstd_cctx_s"
(** [create_compression_context ()] wraps [ZSTD_createCCtx ()]. *)

external create_decompression_context : unit -> decompression_context
  = "caml_create_zstd_dctx_s"
(** [create_decompression_context ()] wraps [ZSTD_createDCtx ()]. *)

type decompression_stream = external "ZSTD_DStream"

external create_decompression_stream : unit -> decompression_stream
  = "caml_create_zstd_dstream"
(** [create_decompression_stream ()] wraps [ZSTD_createDStream ()]. *)

type dictionary = Bstr.t

external version : unit -> int = "caml_zstd_version"
(** [version ()] wraps [ZSTD_VERSION_NUMBER]. *)

external compress_bound : int -> int = "caml_zstd_compress_bound"
(** [compress_bound src_size] wraps [ZSTD_COMPRESSBOUND (src_size)]. *)

external compress_bigstring : Bstr.t -> Bstr.t -> int -> int
  = "caml_zstd_compress_bigstring"
(** [compress_bigstring uncompressed_bigstring compressed_output_bigstring
     level] wraps
    [ZSTD_compress (compressed_output_bigstring, uncompressed_bigstring, level)].
*)

external compress_bigstring_with_context :
  compression_context -> Bstr.t -> Bstr.t -> int -> int
  = "caml_zstd_compress_bigstring_with_context"
(** [compress_bigstring_with_context context uncompressed_bigstring
     compressed_output_bigstring level] wraps
    [ZSTD_compressCCtx (context, compressed_output_bigstring,
     uncompressed_bigstring, level)]. *)

external compress_bigstring_with_context_and_dictionary :
  compression_context -> dictionary -> Bstr.t -> Bstr.t -> int -> int
  = "caml_zstd_compress_bigstring_with_context_and_dictionary"
(** [compress_bigstring_with_context_and_dictionary context dictionary
     uncompressed_bigstring compressed_output_bigstring level] wraps
    [ZSTD_compress_usingDict (context, compressed_output_bigstring,
     uncompressed_bigstring, dictionary, level)]. *)

external compress_string : string -> bytes -> int -> int
  = "caml_zstd_compress_string"
(** [compress_string uncompressed_string compressed_output_bytes level] wraps
    [ZSTD_compress (compressed_output_bytes, uncompressed_string, level)]. *)

external compress_string_with_context :
  compression_context -> string -> bytes -> int -> int
  = "caml_zstd_compress_string_with_context"
(** [compress_string_with_context context uncompressed_string
     compressed_output_bytes level] wraps
    [ZSTD_compressCCtx (context, compressed_output_bytes, uncompressed_string,
     level)]. *)

external compress_string_with_context_and_dictionary :
  compression_context -> dictionary -> string -> bytes -> int -> int
  = "caml_zstd_compress_string_with_context_and_dictionary"
(** [compress_string_with_context_and_dictionary context dictionary
     uncompressed_string compressed_output_bytes level] wraps
    [ZSTD_compress_usingDict (context, compressed_output_bytes,
     uncompressed_string, dictionary, level)]. *)

external decompress_bigstring : Bstr.t -> Bstr.t -> int
  = "caml_zstd_decompress_bigstring"
(** [decompress_bigstring compressed_bigstring uncompressed_output_bigstring]
    wraps
    [ZSTD_decompress (uncompressed_output_bigstring, compressed_bigstring)]. *)

external decompress_bigstring_with_context :
  decompression_context -> Bstr.t -> Bstr.t -> int
  = "caml_zstd_decompress_bigstring_with_context"
(** [decompress_bigstring_with_context context compressed_bigstring
     uncompressed_output_bigstring] wraps
    [ZSTD_decompressDCtx (context, uncompressed_output_bigstring,
     compressed_bigstring)]. *)

external decompress_bigstring_with_context_and_dictionary :
  decompression_context -> dictionary -> Bstr.t -> Bstr.t -> int
  = "caml_zstd_decompress_bigstring_with_context_and_dictionary"
(** [decompress_bigstring_with_context_and_dictionary context dictionary
     compressed_bigstring uncompressed_output_bigstring] wraps
    [ZSTD_decompress_usingDict (context, uncompressed_output_bigstring,
     compressed_bigstring, dictionary)]. *)

external decompress_string : string -> bytes -> int
  = "caml_zstd_decompress_string"
(** [decompress_string compressed_string uncompressed_output_bytes] wraps
    [ZSTD_decompress (uncompressed_output_bytes, compressed_string)]. *)

external decompress_string_with_context :
  decompression_context -> string -> bytes -> int
  = "caml_zstd_decompress_string_with_context"
(** [decompress_string_with_context context compressed_string
     uncompressed_output_bytes] wraps
    [ZSTD_decompressDCtx (context, uncompressed_output_bytes,
     compressed_string)]. *)

external decompress_string_with_context_and_dictionary :
  decompression_context -> dictionary -> string -> bytes -> int
  = "caml_zstd_decompress_string_with_context_and_dictionary"
(** [decompress_string_with_context_and_dictionary context dictionary
     compressed_string uncompressed_output_bytes] wraps
    [ZSTD_decompress_usingDict (context, uncompressed_output_bytes,
     compressed_string, dictionary)]. *)

module Directive = struct
  let continue = 0
  and flush = 1
  and eend = 2
end

external compress_stream2 :
  compression_context -> Io_buffer.t -> Io_buffer.t -> int -> int * int * int
  = "caml_zstd_compress_stream2"
(** [compress_stream2 context in_buffer out_buffer directive] wraps
    [ZSTD_compressStream2 (context, out_buffer, in_buffer, directive)].

    [directive] is one of the {!Directive} values: {!Directive.continue},
    {!Directive.flush}, or {!Directive.eend}.

    The returned triple is [(remaining, input_position, output_position)]. *)

external decompress_stream :
  decompression_stream -> Io_buffer.t -> Io_buffer.t -> int * int * int
  = "caml_zstd_decompress_stream"
(** [decompress_stream dstream in_buffer out_buffer] wraps
    [ZSTD_decompressStream (dstream, out_buffer, in_buffer)].

    The returned triple is [(remaining, input_position, output_position)]. *)
