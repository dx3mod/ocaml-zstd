let decompress_string ~original_size string =
  let bytes = Bytes.create original_size in
  let _ = Bindings.decompress_string bytes string in
  Bytes.unsafe_to_string bytes

let decompress_bigstring ~original_size bs =
  let buffer = Bstr.create original_size in
  let _ =
    Bindings.decompress_bigstring buffer
      Bstr.(length buffer)
      bs
      Bstr.(length bs)
  in
  buffer
