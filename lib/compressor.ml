module Context = struct
  type t = { cctx : Bindings.compression_context; mutex : Mutex.t }

  let create () =
    { cctx = Bindings.create_compression_context (); mutex = Mutex.create () }
end

let compress_bigstring_into ?context ?dictionary ~level uncompressed_bigstring
    compressed_output_bigstring =
  match (context, dictionary) with
  | None, None ->
      Bindings.compress_bigstring uncompressed_bigstring
        compressed_output_bigstring level
  | Some context, None ->
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.compress_bigstring_with_context context.cctx
        uncompressed_bigstring compressed_output_bigstring level
  | Some context, Some dictionary ->
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.compress_bigstring_with_context_and_dictionary context.cctx
        dictionary uncompressed_bigstring compressed_output_bigstring level
  | None, Some dictionary ->
      Bindings.compress_bigstring_with_context_and_dictionary
        Context.(create ()).cctx dictionary uncompressed_bigstring
        compressed_output_bigstring level

let compress_bigstring ?context ?dictionary ~level uncompressed_bigstring =
  let compressed_capacity =
    Bindings.compress_bound @@ Bstr.length uncompressed_bigstring
  in
  let compressed_output_bigstring = Bstr.create compressed_capacity in

  let len =
    compress_bigstring_into ?context ?dictionary ~level uncompressed_bigstring
      compressed_output_bigstring
  in

  Bstr.sub ~off:0 ~len compressed_output_bigstring

let compress_string_into ?context ?dictionary ~level uncompressed_string
    compressed_output_bytes =
  match (context, dictionary) with
  | None, None ->
      Bindings.compress_string uncompressed_string compressed_output_bytes level
  | Some context, None ->
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.compress_string_with_context context.cctx uncompressed_string
        compressed_output_bytes level
  | Some context, Some dictionary ->
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.compress_string_with_context_and_dictionary context.cctx
        dictionary uncompressed_string compressed_output_bytes level
  | None, Some dictionary ->
      Bindings.compress_string_with_context_and_dictionary
        Context.(create ()).cctx dictionary uncompressed_string
        compressed_output_bytes level

let compress_string ?context ?dictionary ~level uncompressed_string =
  let compressed_capacity =
    Bindings.compress_bound @@ String.length uncompressed_string
  in
  let compressed_output_bytes = Bytes.create compressed_capacity in

  let length =
    compress_string_into ?context ?dictionary ~level uncompressed_string
      compressed_output_bytes
  in

  if length = Bytes.length compressed_output_bytes then
    Bytes.unsafe_to_string compressed_output_bytes
  else Bytes.sub_string compressed_output_bytes 0 length

module Stream = struct
  type t = { context : Context.t; mutable closed : bool }

  exception Already_closed

  let create () = { context = Context.create (); closed = false }
  and of_context context = { context; closed = false }

  let compress ~in_buffer ~out_buffer stream directive =
    if stream.closed then raise Already_closed;

    let directive =
      match directive with
      | `Continue -> Bindings.Directive.continue
      | `Flush -> Bindings.Directive.eend
      | `End ->
          stream.closed <- true;
          Bindings.Directive.eend
    in

    let remaining, consumed, compressed =
      Mutex.protect stream.context.mutex @@ fun () ->
      Bindings.compress_stream2 stream.context.cctx in_buffer out_buffer
        directive
    in

    (~remaining, ~consumed, ~compressed)
end
