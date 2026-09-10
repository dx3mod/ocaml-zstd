module Dictionary = struct
  type t
end

let compress_string ~level s =
  let capacity = Bindings.compress_bound String.(length s) in
  let bytes = Bytes.create capacity in

  Bindings.compress_string bytes s level |> Bytes.sub_string bytes 0

let compress_bigstring ~level bs =
  let capacity = Bindings.compress_bound Bstr.(length bs) in
  let buffer = Bstr.create capacity in

  let len =
    Bindings.compress_bigstring buffer capacity bs Bstr.(length bs) level
  in

  Bstr.sub ~off:0 ~len buffer
