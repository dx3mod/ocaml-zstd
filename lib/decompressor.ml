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

let decompress_string ?context ?dictionary compressed_string =
  let uncompressed_output_bytes =
    Bytes.create @@ Bindings.get_decompression_size_of_string compressed_string
  in

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

let decompress_bigstring ?context ?dictionary compressed_bigstring =
  let uncompressed_output_bigstring =
    Bstr.create
    @@ Bindings.get_decompression_size_of_bigstring compressed_bigstring
  in

  decompress_bigstring_into ?context ?dictionary compressed_bigstring
    uncompressed_output_bigstring
  |> ignore;

  uncompressed_output_bigstring

module Stream = struct
  type t = {
    dstream : Bindings.decompression_stream;
    mutex : Mutex.t;
    mutable closed : bool;
  }

  let load_dictionary (dstream : Bindings.decompression_stream) dict =
    Bindings.load_decompression_dictionary (Obj.magic dstream) dict

  let create ?dictionary ?size_limit () =
    let dstream = Bindings.create_decompression_stream () in

    Option.iter
      (fun size ->
        Bindings.set_decompression_stream_parameter dstream 100
        @@ log2 @@ float_of_int size)
      size_limit;

    Option.iter (load_dictionary dstream) dictionary;

    { dstream; mutex = Mutex.create (); closed = false }

  let in_size () = Bindings.get_decompression_stream_in_size ()
  and out_size () = Bindings.get_decompression_stream_out_size ()

  exception Already_closed

  let[@inline] decompress_intf ~in_slice ~out_slice stream f =
    if stream.closed then raise Already_closed;

    let remaining, consumed, decompressed =
      Mutex.protect stream.mutex @@ fun () ->
      f stream.dstream in_slice out_slice
    in

    (~remaining, ~consumed, ~decompressed)

  let decompress ~in_slice ~out_slice stream =
    decompress_intf ~in_slice ~out_slice stream Bindings.decompress_stream

  let decompress_bytes ~in_slice ~out_slice stream =
    decompress_intf ~in_slice ~out_slice stream (fun _ _ _ -> (0, 0, 0))

  let close stream =
    if stream.closed then raise Already_closed else stream.closed <- true
end

module State = struct
  type t = { stream : Stream.t; out_buf : Bstr.t }

  let make ?out_buf ?stream () =
    {
      stream =
        (match stream with None -> Stream.create () | Some stream -> stream);
      out_buf =
        (match out_buf with
        | None -> Bstr.create @@ Stream.out_size ()
        | Some out_buf -> out_buf);
    }

  let create ?dictionary ?size_limit () =
    {
      stream = Stream.create ?dictionary ?size_limit ();
      out_buf = Bstr.create @@ Stream.out_size ();
    }

  let feed state slice =
    let rec aux in_slice =
      let out_slice = Slice_bstr.make state.out_buf in

      let ~remaining, ~consumed, ~decompressed =
        Stream.decompress ~in_slice ~out_slice state.stream
      in

      let in_slice_len = Slice_bstr.length in_slice in

      if (remaining > 0 || consumed > 0) && consumed < in_slice_len then
        aux
        @@ Slice_bstr.sub ~off:consumed ~len:(in_slice_len - consumed) in_slice
      else Slice_bstr.sub ~off:0 ~len:decompressed out_slice
    in

    aux slice
end

let decompress_channel ?dictionary ?size_limit ic oc =
  let state = State.create ?dictionary ?size_limit () in
  let in_buf = Bstr.create @@ Stream.in_size () in

  let rec loop () =
    match In_channel.input_bigarray ic in_buf 0 (Bstr.length in_buf) with
    | 0 -> ()
    | len ->
        let Slice.{ buf; off; len } =
          State.feed state Slice_bstr.(make ~off:0 ~len in_buf)
        in

        Out_channel.output_bigarray oc buf off len;
        loop ()
  in

  loop ();
  (* State.finish state; *)
  Out_channel.flush oc
