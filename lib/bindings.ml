type cctx = external "cctx"

external version : unit -> int = "caml_zstd_version"

external compress_string : bytes -> string -> int -> int
  = "caml_zstd_compress_string"

external compress_bigstring : Bstr.t -> int -> Bstr.t -> int -> int -> int
  = "caml_zstd_compress_bigstring"

external compress_bound : int -> int = "caml_zstd_compress_bound"

external decompress_string : bytes -> string -> int
  = "caml_zstd_decompress_string"

external decompress_bigstring : Bstr.t -> int -> Bstr.t -> int -> int
  = "caml_zstd_decompress_bigstring"

(* external decompress : string -> int -> cctx option -> string
  = "caml_zstd_decompress" *)
