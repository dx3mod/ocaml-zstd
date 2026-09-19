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

  let create ?dictionary ?level () =
    let context = Context.create () in

    Option.iter (Context.set_compression_level context) level;
    Option.iter (Context.load_dictionary context) dictionary;

    { context; closed = false }

  and of_context context = { context; closed = false }

  let in_size () = Bindings.get_compression_stream_in_size ()
  and out_size () = Bindings.get_compression_stream_out_size ()

  exception Already_closed

  let[@inline] compress_intf ~in_slice ~out_slice stream directive f =
    if stream.closed then raise Already_closed;

    let raw_directive =
      match directive with
      | `Continue -> Bindings.Directive.continue
      | `Flush -> Bindings.Directive.flush
      | `End -> Bindings.Directive.eend
    in

    let remaining, consumed, compressed =
      Mutex.protect stream.context.mutex @@ fun () ->
      f stream.context.cctx in_slice out_slice raw_directive
    in

    begin match directive with
    | `End when remaining = 0 -> stream.closed <- true
    | `End | `Continue | `Flush -> ()
    end;

    (~remaining, ~consumed, ~compressed)

  let compress ~in_slice ~out_slice stream directive =
    compress_intf ~in_slice ~out_slice stream directive
      Bindings.compress_stream2

  let compress_bytes ~in_slice ~out_slice stream directive =
    compress_intf ~in_slice ~out_slice stream directive
      Bindings.compress_stream2_bytes

  let close stream =
    if stream.closed then raise Already_closed else stream.closed <- true
end

module State = struct
  type t = { stream : Stream.t; out_buf : Bstr.t }

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

  let feed state slice directive =
    let rec aux in_slice =
      let out_slice = Slice_bstr.make state.out_buf in

      let ~remaining, ~consumed, ~compressed =
        Stream.compress ~in_slice ~out_slice state.stream directive
      in

      let in_slice_len = Slice_bstr.length in_slice in

      if remaining <> 0 || (consumed > 0 && consumed < in_slice_len) then
        aux
        @@ Slice_bstr.sub ~off:consumed ~len:(in_slice_len - consumed) in_slice
      else Slice_bstr.sub ~off:0 ~len:compressed out_slice
    in

    aux slice

  let finish state = feed state Slice_bstr.empty `End
end

let compress_channel ?dictionary ~level ic oc =
  let state = State.create ?dictionary ~level () in
  let in_buf = Bstr.create @@ Stream.in_size () in

  let output Slice.{ buf; off; len } =
    Out_channel.output_bigarray oc buf off len
  in

  let rec loop () =
    match In_channel.input_bigarray ic in_buf 0 (Bstr.length in_buf) with
    | 0 -> State.finish state |> output
    | len ->
        State.feed state Slice_bstr.(make ~len in_buf) `Continue |> output;
        loop ()
  in

  loop ();
  Out_channel.flush oc
