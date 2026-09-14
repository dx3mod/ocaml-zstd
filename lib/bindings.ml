(** Low-level bindings to the Zstandard C library. *)

type compression_context = external "ZSTD_CCtx"
and decompression_context = external "ZSTD_DCtx"

external create_compression_context : unit -> compression_context
  = "caml_create_zstd_cctx_s"
(** [create_compression_context ()] creates a compression context. *)

external create_decompression_context : unit -> decompression_context
  = "caml_create_zstd_dctx_s"
(** [create_decompression_context ()] creates a decompression context. *)

type decompression_stream = external "ZSTD_DStream"

external create_decompression_stream : unit -> decompression_stream
  = "caml_create_zstd_dstream"
(** [create_decompression_stream ()] creates a decompression stream. *)

type dictionary = Bstr.t
(** A dictionary, as a bigstring. *)

external version : unit -> int = "caml_zstd_version"
(** [version ()] returns the Zstandard version number. *)

external compress_bound : int -> int = "caml_zstd_compress_bound"
(** [compress_bound src_size] returns an upper bound on the compressed size for
    an input of [src_size] bytes. *)

external compress_bigstring : Bstr.t -> Bstr.t -> int -> int
  = "caml_zstd_compress_bigstring"
(** [compress_bigstring uncompressed compressed level] compresses [uncompressed]
    into [compressed] at [level]. *)

external compress_bigstring_with_context :
  compression_context -> Bstr.t -> Bstr.t -> int -> int
  = "caml_zstd_compress_bigstring_with_context"
(** [compress_bigstring_with_context context uncompressed compressed level]
    compresses [uncompressed] into [compressed] at [level], reusing [context].
*)

external compress_bigstring_with_context_and_dictionary :
  compression_context -> dictionary -> Bstr.t -> Bstr.t -> int -> int
  = "caml_zstd_compress_bigstring_with_context_and_dictionary"
(** [compress_bigstring_with_context_and_dictionary context dictionary
     uncompressed compressed level] compresses [uncompressed] into [compressed]
    at [level], using [context] and [dictionary]. *)

external compress_string : string -> bytes -> int -> int
  = "caml_zstd_compress_string"
(** [compress_string uncompressed compressed level] compresses [uncompressed]
    into [compressed] at [level]. *)

external compress_string_with_context :
  compression_context -> string -> bytes -> int -> int
  = "caml_zstd_compress_string_with_context"
(** [compress_string_with_context context uncompressed compressed level]
    compresses [uncompressed] into [compressed] at [level], reusing [context].
*)

external compress_string_with_context_and_dictionary :
  compression_context -> dictionary -> string -> bytes -> int -> int
  = "caml_zstd_compress_string_with_context_and_dictionary"
(** [compress_string_with_context_and_dictionary context dictionary uncompressed
     compressed level] compresses [uncompressed] into [compressed] at [level],
    using [context] and [dictionary]. *)

external decompress_bigstring : Bstr.t -> Bstr.t -> int
  = "caml_zstd_decompress_bigstring"
(** [decompress_bigstring compressed uncompressed] decompresses [compressed]
    into [uncompressed]. *)

external decompress_bigstring_with_context :
  decompression_context -> Bstr.t -> Bstr.t -> int
  = "caml_zstd_decompress_bigstring_with_context"
(** [decompress_bigstring_with_context context compressed uncompressed]
    decompresses [compressed] into [uncompressed], reusing [context]. *)

external decompress_bigstring_with_context_and_dictionary :
  decompression_context -> dictionary -> Bstr.t -> Bstr.t -> int
  = "caml_zstd_decompress_bigstring_with_context_and_dictionary"
(** [decompress_bigstring_with_context_and_dictionary context dictionary
     compressed uncompressed] decompresses [compressed] into [uncompressed],
    using [context] and [dictionary]. *)

external decompress_string : string -> bytes -> int
  = "caml_zstd_decompress_string"
(** [decompress_string compressed uncompressed] decompresses [compressed] into
    [uncompressed]. *)

external decompress_string_with_context :
  decompression_context -> string -> bytes -> int
  = "caml_zstd_decompress_string_with_context"
(** [decompress_string_with_context context compressed uncompressed]
    decompresses [compressed] into [uncompressed], reusing [context]. *)

external decompress_string_with_context_and_dictionary :
  decompression_context -> dictionary -> string -> bytes -> int
  = "caml_zstd_decompress_string_with_context_and_dictionary"
(** [decompress_string_with_context_and_dictionary context dictionary compressed
     uncompressed] decompresses [compressed] into [uncompressed], using
    [context] and [dictionary]. *)

(** [Directive.continue], [Directive.flush] and [Directive.eend] are the flush
    directives for the streaming compressor. *)
module Directive = struct
  let continue = 0
  and flush = 1
  and eend = 2
end

external compress_stream2 :
  compression_context -> Io_buffer.t -> Io_buffer.t -> int -> int * int * int
  = "caml_zstd_compress_stream2"
(** [compress_stream2 context in_buffer out_buffer directive] feeds [in_buffer]
    through the streaming compressor into [out_buffer] with [directive]. *)

external decompress_stream :
  decompression_stream -> Io_buffer.t -> Io_buffer.t -> int * int * int
  = "caml_zstd_decompress_stream"
(** [decompress_stream stream in_buffer out_buffer] feeds [in_buffer] through
    the streaming decompressor into [out_buffer]. *)
