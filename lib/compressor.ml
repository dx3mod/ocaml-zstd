module Context = struct
  type t = { cctx : Bindings.compression_context }

  let create () = { cctx = Bindings.create_compression_context () }
end

let compress_bigstring ?context ?dictionary ~level bs =
  let compressed_capacity = Bindings.compress_bound @@ Bstr.length bs in
  let buffer = Bstr.create compressed_capacity and length = Bstr.length bs in

  let len =
    match (context, dictionary) with
    | None, None ->
        Bindings.compress_bigstring bs length buffer compressed_capacity level
    | Some context, None ->
        Bindings.compress_bigstring_with_context context.Context.cctx bs length
          buffer compressed_capacity level
    | Some context, Some dictionary ->
        Bindings.compress_bigstring_with_context_and_dictionary
          context.Context.cctx dictionary bs length buffer compressed_capacity
          level
    | None, Some dictionary ->
        Bindings.compress_bigstring_with_context_and_dictionary
          Context.(create ()).cctx dictionary bs length buffer
          compressed_capacity level
  in

  Bstr.sub ~off:0 ~len buffer

let compress_string ?context ?dictionary ~level s =
  let compressed_capacity = Bindings.compress_bound @@ String.length s in
  let bytes = Bytes.create compressed_capacity and length = String.length s in

  let length =
    match (context, dictionary) with
    | None, None ->
        Bindings.compress_string s length bytes compressed_capacity level
    | Some context, None ->
        Bindings.compress_string_with_context context.Context.cctx s length
          bytes compressed_capacity level
    | Some context, Some dictionary ->
        Bindings.compress_string_with_context_and_dictionary
          context.Context.cctx dictionary s length bytes compressed_capacity
          level
    | None, Some dictionary ->
        Bindings.compress_string_with_context_and_dictionary
          Context.(create ()).cctx dictionary s
          String.(length s)
          bytes compressed_capacity level
  in

  Bytes.sub_string bytes 0 length

module Stream = struct
  type t = Context.t

  let create () = Context.create ()
  and of_context context = context

  let compress ~in_buffer ~out_buffer context directive =
    let directive =
      match directive with
      | `Continue -> Bindings.Directive.continue
      | `Flush -> Bindings.Directive.eend
      | `End -> Bindings.Directive.eend
    in

    let remaining, compressed, written =
      Bindings.compress_stream2 context.Context.cctx in_buffer out_buffer
        directive
    in

    (~remaining, ~compressed, ~written)
end
