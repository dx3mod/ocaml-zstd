module Context = struct
  type t = { cctx : Bindings.compression_context; mutex : Mutex.t }

  let create () =
    { cctx = Bindings.create_compression_context (); mutex = Mutex.create () }

  let set_compression_level context level =
    Mutex.protect context.mutex @@ fun () ->
    Bindings.(
      set_compression_context_parameter context.cctx
        Compression_context_parameters.compression_level level)

  let load_dictionary context dict =
    Bindings.load_compression_dictionary context.cctx dict
end

module Frame = struct
  type t = [ `String of string | `Bigstring of Bstr.t ]

  let uncompressed_size = function
    | `String string -> Bindings.get_decompression_size_of_string string
    | `Bigstring bigstring ->
        Bindings.get_decompression_size_of_bigstring bigstring
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

  let create ?dictionary ?level () =
    let context = Context.create () in

    Option.iter (Context.set_compression_level context) level;
    Option.iter (Context.load_dictionary context) dictionary;

    { context; closed = false }

  and of_context context = { context; closed = false }

  let in_size () = Bindings.get_compression_stream_in_size ()
  and out_size () = Bindings.get_compression_stream_out_size ()

  let compress ~in_buffer ~out_buffer stream directive =
    if stream.closed then raise Already_closed;

    let directive =
      match directive with
      | `Continue -> Bindings.Directive.continue
      | `Flush -> Bindings.Directive.flush
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

module State = struct
  type nonrec t = { stream : Stream.t; out_buf : Bstr.t }

  let make ?out_buf stream =
    {
      stream;
      out_buf =
        (match out_buf with
        | None -> Bstr.create @@ Stream.out_size ()
        | Some out_buf -> out_buf);
    }

  let create ?dictionary ?level () =
    {
      stream = Stream.create ?dictionary ?level ();
      out_buf = Bstr.create @@ Stream.out_size ();
    }

  let rec feed ~output state buffer pos size directive =
    let in_buffer = Io_buffer.make ~pos ~size buffer in
    let out_buffer = Io_buffer.make state.out_buf in

    let ~remaining, ~consumed, ~compressed =
      Stream.compress ~in_buffer ~out_buffer state.stream directive
    in

    if compressed > 0 then output state.out_buf 0 compressed;

    match directive with
    | `End ->
        if remaining <> 0 then feed state ~output buffer pos size directive
    | `Continue ->
        if consumed < in_buffer.Io_buffer.size then
          feed state ~output buffer pos size directive
    | `Flush -> ()

  let finish ~output state = feed state ~output Bstr.empty 0 0 `End
end

let compress_channel ?dictionary ~level ic oc =
  let state = State.create ?dictionary ~level () in
  let in_buf = Bstr.create @@ Stream.in_size () in

  let output = Out_channel.output_bigarray oc in

  let rec loop () =
    match In_channel.input_bigarray ic in_buf 0 (Bstr.length in_buf) with
    | 0 -> State.finish ~output state
    | length ->
        State.feed state ~output in_buf 0 length `Continue;
        loop ()
  in

  loop ();
  Out_channel.flush oc
