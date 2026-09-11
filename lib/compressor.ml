type t = { cctx : Bindings.Cctx.t }

let create () = { cctx = Bindings.Cctx.create () }

let compress_bigstring c ?dictionary ~level bs =
  let compressed_capacity = Bindings.Misc.compress_bound @@ Bstr.length bs in
  let buffer = Bstr.create compressed_capacity in

  let len =
    Bindings.compress_bigstring_cctx c.cctx dictionary buffer
      Bstr.(length buffer)
      bs
      Bstr.(length bs)
      level
  in

  Bstr.sub ~off:0 ~len buffer

let compress_string c ?dictionary ~level str =
  let compressed_capacity = Bindings.Misc.compress_bound @@ String.length str in
  let bytes = Bytes.create compressed_capacity in

  Bindings.compress_string_cctx c.cctx dictionary str bytes level
  |> Bytes.sub_string bytes 0
