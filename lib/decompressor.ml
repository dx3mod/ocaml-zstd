let log2 x = log x /. log 2.0 |> int_of_float

module Context = struct
  type t = { dctx : Bindings.decompression_context; mutex : Mutex.t }

  let create () =
    { dctx = Bindings.create_decompression_context (); mutex = Mutex.create () }

  let set_size_limit context size =
    Bindings.set_decompression_context_parameter context.dctx 100
      (log2 @@ float_of_int size)

  let load_dictionary context dict =
    Bindings.load_decompression_dictionary context.dctx dict
end

let decompress_string_into_bytes ?context ?dictionary compressed_string
    uncompressed_output_bytes =
  match (context, dictionary) with
  | None, None ->
      Bindings.decompress_string compressed_string uncompressed_output_bytes
  | Some context, None ->
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.decompress_string_with_context context.dctx compressed_string
        uncompressed_output_bytes
  | Some context, Some dictionary ->
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.decompress_string_with_context_and_dictionary context.dctx
        dictionary compressed_string uncompressed_output_bytes
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
      Mutex.protect context.Context.mutex @@ fun () ->
      Bindings.decompress_bigstring_with_context context.dctx
        compressed_bigstring uncompressed_output_bigstring
  | Some context, Some dictionary ->
      Mutex.protect context.mutex @@ fun () ->
      Bindings.decompress_bigstring_with_context_and_dictionary context.dctx
        dictionary compressed_bigstring uncompressed_output_bigstring
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
  type t = { dstream : Bindings.decompression_stream; mutex : Mutex.t }

  let create ?dictionary ?size_limit () =
    let dstream = Bindings.create_decompression_stream () in

    Option.iter
      (fun size ->
        Bindings.set_decompression_stream_parameter dstream 100
        @@ log2 @@ float_of_int size)
      size_limit;

    Option.iter
      (Bindings.load_decompression_dictionary (Obj.magic dstream))
      dictionary;

    { dstream; mutex = Mutex.create () }

  let in_size () = Bindings.get_decompression_stream_in_size ()
  and out_size () = Bindings.get_decompression_stream_out_size ()

  let load_dictionary stream dict =
    Bindings.load_decompression_dictionary (Obj.magic stream.dstream) dict

  let decompress ~in_buffer ~out_buffer stream =
    let remaining, consumed, decompressed =
      Mutex.protect stream.mutex @@ fun () ->
      Bindings.decompress_stream stream.dstream in_buffer out_buffer
    in

    (~remaining, ~consumed, ~decompressed)
end

module State = struct
  type nonrec t = { stream : Stream.t; out_buf : Bstr.t; closed : bool }

  let make ?out_buf ?stream () =
    {
      stream =
        (match stream with None -> Stream.create () | Some stream -> stream);
      closed = false;
      out_buf =
        (match out_buf with
        | None -> Bstr.create @@ Stream.out_size ()
        | Some out_buf -> out_buf);
    }

  let create () =
    {
      stream = Stream.create ();
      out_buf = Bstr.create @@ Stream.out_size ();
      closed = false;
    }

  exception Already_closed

  let feed ~output state buffer pos size =
    if state.closed then raise Already_closed;

    let rec go pos =
      let in_buffer = Io_buffer.make ~pos ~size buffer in
      let out_buffer = Io_buffer.make state.out_buf in

      let ~remaining:_, ~consumed, ~decompressed =
        Stream.decompress ~in_buffer ~out_buffer state.stream
      in

      if decompressed > 0 then output state.out_buf 0 decompressed;
      if consumed < size then go consumed
    in

    go pos
end

let decompress_channel ic oc =
  let state = State.create () in
  let in_buf = Bstr.create @@ Stream.in_size () in
  let output = Out_channel.output_bigarray oc in

  let rec loop () =
    match In_channel.input_bigarray ic in_buf 0 (Bstr.length in_buf) with
    | 0 -> ()
    | length ->
        State.feed ~output state in_buf 0 length;
        loop ()
  in

  loop ();
  Out_channel.flush oc
