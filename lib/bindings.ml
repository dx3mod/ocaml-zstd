module Cctx = struct
  type t

  external create : unit -> t = "caml_create_zstd_cctx_s"
end

module Dctx = struct
  type t

  external create : unit -> t = "caml_create_zstd_dctx_s"
end

module Dstream = struct
  type t

  external create : unit -> t = "caml_create_zstd_dstream"
end

module Dict = struct
  type t = string
end

module Misc = struct
  external version : unit -> int = "caml_zstd_version"
  external compress_bound : int -> int = "caml_zstd_compress_bound"
end

external compress_bigstring : Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring"

external compress_bigstring_with_context :
  Cctx.t -> Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring_with_context_bytecode"
    "caml_zstd_compress_bigstring_with_context"

external compress_bigstring_with_context_and_dictionary :
  Cctx.t -> Dict.t -> Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring_with_context_and_dictionary_bytecode"
    "caml_zstd_compress_bigstring_with_context_and_dictionary"

external compress_string : string -> int -> bytes -> int -> int -> int
  = "caml_zstd_compress_string"

external compress_string_with_context :
  Cctx.t -> string -> int -> bytes -> int -> int -> int
  = "caml_zstd_compress_string_with_context_bytecode"
    "caml_zstd_compress_string_with_context"

external compress_string_with_context_and_dictionary :
  Cctx.t -> Dict.t -> string -> int -> bytes -> int -> int -> int
  = "caml_zstd_compress_string_with_context_and_dictionary_bytecode"
    "caml_zstd_compress_string_with_context_and_dictionary"

external decompress_bigstring : Bstr.t -> Bstr.t -> int -> int -> int
  = "caml_zstd_decompress_bigstring"

external decompress_bigstring_with_context :
  Dctx.t -> Bstr.t -> Bstr.t -> int -> int -> int
  = "caml_zstd_decompress_bigstring_with_context"

external decompress_bigstring_with_context_and_dictionary :
  Dctx.t -> Dict.t -> Bstr.t -> Bstr.t -> int -> int -> int
  = "caml_zstd_decompress_bigstring_with_context_and_dictionary_bytecode"
    "caml_zstd_decompress_bigstring_with_context_and_dictionary"

external decompress_string : string -> bytes -> int -> int
  = "caml_zstd_decompress_string"

external decompress_string_with_context :
  Dctx.t -> string -> bytes -> int -> int
  = "caml_zstd_decompress_string_with_context"

external decompress_string_with_context_and_dictionary :
  Dctx.t -> Dict.t -> string -> bytes -> int -> int
  = "caml_zstd_decompress_string_with_context_and_dictionary"

module Directive = struct
  let continue = 0
  and flush = 1
  and eend = 2
end

external compress_stream2 : Cctx.t -> Bstr.t -> Bstr.t -> int -> int * int * int
  = "caml_zstd_compress_stream2"

external decompress_stream : Dstream.t -> Bstr.t -> Bstr.t -> int * int * int
  = "caml_zstd_decompress_stream"
