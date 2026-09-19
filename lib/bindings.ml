(** Low-level bindings to the Zstandard C library. *)

type compression_context = external "ZSTD_CCtx"
and decompression_context = external "ZSTD_DCtx"

external create_compression_context : unit -> compression_context
  = "caml_create_zstd_cctx_s"
(** [create_compression_context ()] creates a compression context. *)

module Compression_context_parameters = struct
  let compression_level = 100
end

external set_compression_context_parameter :
  compression_context -> int -> int -> unit = "caml_create_zstd_set_cctx_param"
(** [set_compression_context_parameter context param value] sets [param] to
    [value] on [context]. *)

external load_compression_dictionary : compression_context -> Bstr.t -> unit
  = "caml_create_zstd_load_cdict"
(** [load_compression_dictionary context dictionary] loads [dictionary] into
    [context]. *)

external create_decompression_context : unit -> decompression_context
  = "caml_create_zstd_dctx_s"
(** [create_decompression_context ()] creates a decompression context. *)

external set_decompression_context_parameter :
  decompression_context -> int -> int -> unit
  = "caml_create_zstd_set_dctx_param"
(** [set_decompression_context_parameter context param value] sets [param] to
    [value] on [context]. *)

external load_decompression_dictionary : decompression_context -> Bstr.t -> unit
  = "caml_create_zstd_load_ddict"
(** [load_decompression_dictionary context dictionary] loads [dictionary] into
    [context]. *)

type decompression_stream = external "ZSTD_DCtx"

external create_decompression_stream : unit -> decompression_stream
  = "caml_create_zstd_dstream"
(** [create_decompression_stream ()] creates a decompression stream. *)

external set_decompression_stream_parameter :
  decompression_stream -> int -> int -> unit = "caml_create_zstd_set_dctx_param"
(** [set_decompression_stream_parameter stream param value] sets [param] to
    [value] on [stream]. *)

type dictionary = Bstr.t
(** A dictionary, as a bigstring. *)

external version : unit -> int = "caml_zstd_version"
(** [version ()] returns the Zstandard version number. *)

external compress_bound : int -> int = "caml_zstd_compress_bound"
(** [compress_bound src_size] returns an upper bound on the compressed size for
    an input of [src_size] bytes. *)

external get_decompression_size_of_string : string -> int
  = "caml_get_frame_string_content_size"
(** [get_decompression_size_of_string compressed] returns the decompressed size
    of [compressed]. *)

external get_decompression_size_of_bigstring : Bstr.t -> int
  = "caml_get_frame_bigstring_content_size"
(** [get_decompression_size_of_bigstring compressed] returns the decompressed
    size of [compressed]. *)

external get_decompression_stream_out_size : unit -> int
  = "caml_zstd_decompression_stream_out_size"
(** [get_decompression_stream_out_size ()] returns the recommended output buffer
    size for decompression streams. *)

external get_decompression_stream_in_size : unit -> int
  = "caml_zstd_decompression_stream_in_size"
(** [get_decompression_stream_in_size ()] returns the recommended input buffer
    size for decompression streams. *)

external get_compression_stream_out_size : unit -> int
  = "caml_zstd_compression_stream_out_size"
(** [get_compression_stream_out_size ()] returns the recommended output buffer
    size for compression streams. *)

external get_compression_stream_in_size : unit -> int
  = "caml_zstd_compression_stream_in_size"
(** [get_compression_stream_in_size ()] returns the recommended input buffer
    size for compression streams. *)

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
  compression_context -> Slice_bstr.t -> Slice_bstr.t -> int -> int * int * int
  = "caml_zstd_compress_stream2"
(** [compress_stream2 context in_slice out_slice directive] feeds [in_slice]
    through the streaming compressor into [out_slice] with [directive]. *)

external compress_stream2_bytes :
  compression_context ->
  Slice_bytes.t ->
  Slice_bytes.t ->
  int ->
  int * int * int = "caml_zstd_compress_stream2_bytes"
(** [compress_stream2_bytes context in_slice out_slice directive] *)

external decompress_stream :
  decompression_stream -> Slice_bstr.t -> Slice_bstr.t -> int * int * int
  = "caml_zstd_decompress_stream"
(** [decompress_stream stream in_slice out_slice] feeds [in_slice] through the
    streaming decompressor into [out_slice]. *)

external decompress_stream_bytes :
  decompression_stream -> Slice_bytes.t -> Slice_bytes.t -> int * int * int
  = "caml_zstd_decompress_stream_bytes"
(** [decompress_stream_bytes stream in_slice out_slice] *)
