module Context = struct
  type t = { dctx : Bindings.Dctx.t }

  let create () = { dctx = Bindings.Dctx.create () }
end

let decompress_string_into_bytes ?context ?dictionary ~original_size string
    bytes =
  match (context, dictionary) with
  | None, None -> Bindings.decompress_string string bytes original_size
  | Some context, None ->
      Bindings.decompress_string_with_context context.Context.dctx string bytes
        original_size
  | Some context, Some dictionary ->
      Bindings.decompress_string_with_context_and_dictionary
        context.Context.dctx dictionary string bytes original_size
  | None, Some dictionary ->
      Bindings.decompress_string_with_context_and_dictionary
        Context.(create ()).dctx dictionary string bytes original_size

let decompress_string ?context ?dictionary ~original_size string =
  let bytes = Bytes.create original_size in
  let length =
    decompress_string_into_bytes ?context ?dictionary ~original_size string
      bytes
  in

  if length = original_size then Bytes.unsafe_to_string bytes
  else Bytes.sub_string bytes 0 length

let decompress_bigstring_into ?context ?dictionary ~original_size bs buffer =
  match (context, dictionary) with
  | None, None ->
      Bindings.decompress_bigstring bs buffer Bstr.(length buffer) original_size
  | Some context, None ->
      Bindings.decompress_bigstring_with_context context.Context.dctx bs buffer
        Bstr.(length buffer)
        original_size
  | Some context, Some dictionary ->
      Bindings.decompress_bigstring_with_context_and_dictionary
        context.Context.dctx dictionary bs buffer
        Bstr.(length buffer)
        original_size
  | None, Some dictionary ->
      Bindings.decompress_bigstring_with_context_and_dictionary
        Context.(create ()).dctx dictionary bs buffer
        Bstr.(length buffer)
        original_size

let decompress_bigstring ?context ?dictionary ~original_size bs =
  let buffer = Bstr.create original_size in
  let len =
    decompress_bigstring_into ?context ?dictionary ~original_size bs buffer
  in

  if len = original_size then buffer else Bstr.sub ~off:0 ~len buffer

module Stream = struct
  type t = { dstream : Bindings.Dstream.t }
  and step = { remaining : int; consumed : int; decompressed : int }

  let create () = { dstream = Bindings.Dstream.create () }

  let decompress ~into:buffer stream chunk =
    let remaining, consumed, decompressed =
      Bindings.decompress_stream stream.dstream chunk buffer
    in
    { remaining; consumed; decompressed }
end
