module Dictionary = struct
  type t = string
end

let decompress_string ?dictionary ~original_size string =
  let bytes = Bytes.create original_size in
  let _ = Bindings.decompress_string dictionary bytes string in
  Bytes.unsafe_to_string bytes

let decompress_bigstring ?dictionary ~original_size bs =
  let buffer = Bstr.create original_size in
  let len =
    Bindings.decompress_bigstring dictionary bs
      Bstr.(length bs)
      buffer original_size
  in
  Bstr.sub ~off:0 ~len buffer
