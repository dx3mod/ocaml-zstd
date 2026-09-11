type t = { dctx : Bindings.Dctx.t }

let create () = { dctx = Bindings.Dctx.create () }

let decompress_string d ?dictionary ~original_size string =
  let bytes = Bytes.create original_size in
  let _ = Bindings.decompress_string_dctx d.dctx dictionary bytes string in
  Bytes.unsafe_to_string bytes

let decompress_bigstring d ?dictionary ~original_size bs =
  let buffer = Bstr.create original_size in
  let len =
    Bindings.decompress_bigstring d.dctx dictionary bs
      Bstr.(length bs)
      buffer original_size
  in
  Bstr.sub ~off:0 ~len buffer
