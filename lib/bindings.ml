module Cctx = struct
  type t = external "ZSTD_CCtx"

  external create : unit -> t = "caml_create_zstd_cctx_s"
end

module Dctx = struct
  type t = external "ZSTD_DCtx"

  external create : unit -> t = "caml_create_zstd_dctx_s"
end

module Misc = struct
  external version : unit -> int = "caml_zstd_version"
  external compress_bound : int -> int = "caml_zstd_compress_bound"
end

external compress_bigstring_cctx :
  Cctx.t -> string option -> Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring_bytecode" "caml_zstd_compress_bigstring"

external compress_string_cctx :
  Cctx.t -> string option -> string -> bytes -> int -> int
  = "caml_zstd_compress_string"

external decompress_string_dctx :
  Dctx.t -> string option -> bytes -> string -> int
  = "caml_zstd_decompress_string"

external decompress_bigstring :
  Dctx.t -> string option -> Bstr.t -> int -> Bstr.t -> int -> int
  = "caml_zstd_decompress_bigstring_bytecode" "caml_zstd_decompress_bigstring"
