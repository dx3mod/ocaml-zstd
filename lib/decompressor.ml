module Context = struct
  type t = { dctx : Bindings.decompression_context }

  let create () = { dctx = Bindings.create_decompression_context () }
end

let decompress_string_into_bytes ?context ?dictionary compressed_string
    uncompressed_output_bytes =
  match (context, dictionary) with
  | None, None ->
      Bindings.decompress_string compressed_string uncompressed_output_bytes
  | Some context, None ->
      Bindings.decompress_string_with_context context.Context.dctx
        compressed_string uncompressed_output_bytes
  | Some context, Some dictionary ->
      Bindings.decompress_string_with_context_and_dictionary
        context.Context.dctx dictionary compressed_string
        uncompressed_output_bytes
  | None, Some dictionary ->
      Bindings.decompress_string_with_context_and_dictionary
        Context.(create ()).dctx dictionary compressed_string
        uncompressed_output_bytes

let decompress_string ?context ?dictionary ~original_size compressed_string =
  let uncompressed_output_bytes = Bytes.create original_size in

  decompress_string_into_bytes ?context ?dictionary compressed_string
    uncompressed_output_bytes
  |> ignore;

  Bytes.unsafe_to_string uncompressed_output_bytes

let decompress_bigstring_into ?context ?dictionary compressed_bigstring
    uncompressed_output_bigstring =
  match (context, dictionary) with
  | None, None ->
      Bindings.decompress_bigstring compressed_bigstring
        uncompressed_output_bigstring
  | Some context, None ->
      Bindings.decompress_bigstring_with_context context.Context.dctx
        compressed_bigstring uncompressed_output_bigstring
  | Some context, Some dictionary ->
      Bindings.decompress_bigstring_with_context_and_dictionary
        context.Context.dctx dictionary compressed_bigstring
        uncompressed_output_bigstring
  | None, Some dictionary ->
      Bindings.decompress_bigstring_with_context_and_dictionary
        Context.(create ()).dctx dictionary compressed_bigstring
        uncompressed_output_bigstring

let decompress_bigstring ?context ?dictionary ~original_size
    compressed_bigstring =
  let uncompressed_output_bigstring = Bstr.create original_size in

  decompress_bigstring_into ?context ?dictionary compressed_bigstring
    uncompressed_output_bigstring
  |> ignore;

  uncompressed_output_bigstring

module Stream = struct
  type t = { dstream : Bindings.decompression_stream }

  let create () = { dstream = Bindings.create_decompression_stream () }

  let decompress ~in_buffer ~out_buffer stream =
    let remaining, consumed, decompressed =
      Bindings.decompress_stream stream.dstream in_buffer out_buffer
    in

    (~remaining, ~consumed, ~decompressed)
end
