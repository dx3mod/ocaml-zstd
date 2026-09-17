(** Compress a string using the streaming State API. *)
let compress_stream ?(level = 3) data =
  let buf = Buffer.create 256 in
  let push bs pos len =
    Buffer.add_string buf (Bstr.sub ~off:pos ~len bs |> Bstr.to_string)
  in
  let state = Ozstd.Compressor.State.create ~level () in
  let bs = Bstr.of_string data in
  Ozstd.Compressor.State.feed ~push state bs 0 (Bstr.length bs) `Continue;
  Ozstd.Compressor.State.finish ~push state;
  Buffer.contents buf

(** Decompress a string using the streaming State API. *)
let decompress_stream ?size_limit compressed =
  let buf = Buffer.create 256 in
  let push bs pos len =
    Buffer.add_string buf (Bstr.sub ~off:pos ~len bs |> Bstr.to_string)
  in
  let state = Ozstd.Decompressor.State.create ?size_limit () in
  let bs = Bstr.of_string compressed in
  Ozstd.Decompressor.State.feed ~push state bs 0 (Bstr.length bs);
  Ozstd.Decompressor.State.finish state;
  Buffer.contents buf

(* ------------------------------------------------------------------ *)
(* Test cases                                                         *)
(* ------------------------------------------------------------------ *)

let test_version () =
  let major, minor, patch = Ozstd.version () in
  Alcotest.(check bool) "major >= 1" true (major >= 1);
  Alcotest.(check bool) "minor >= 0" true (minor >= 0);
  Alcotest.(check bool) "patch >= 0" true (patch >= 0)

let test_string_roundtrip () =
  let data = "Hello, Zstandard! This is a test." in
  let compressed = Ozstd.Compressor.compress_string ~level:3 data in
  let decompressed = Ozstd.Decompressor.decompress_string compressed in
  Alcotest.(check string) "decompressed equals original" data decompressed

let test_bigstring_roundtrip () =
  let data = Bstr.of_string "Hello, Zstandard! This is a test." in
  let compressed = Ozstd.Compressor.compress_bigstring ~level:3 data in
  let decompressed = Ozstd.Decompressor.decompress_bigstring compressed in
  Alcotest.(check int) "length" (Bstr.length data) (Bstr.length decompressed);
  Alcotest.(check bool)
    "content" true
    (Bstr.to_string data = Bstr.to_string decompressed)

let test_compression_levels () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  for level = 1 to 19 do
    let compressed = Ozstd.Compressor.compress_string ~level data in
    let decompressed = Ozstd.Decompressor.decompress_string compressed in
    Alcotest.(check string) (Printf.sprintf "level %d" level) data decompressed
  done

let test_stream_roundtrip () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let compressed = compress_stream data in
  let decompressed = decompress_stream compressed in
  Alcotest.(check string) "stream roundtrip" data decompressed

let test_simple_to_stream () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let compressed = Ozstd.Compressor.compress_string ~level:3 data in
  let decompressed = decompress_stream compressed in
  Alcotest.(check string) "simple to stream" data decompressed

let test_stream_to_simple () =
  (* NOTE: streaming compression does not embed the frame content size
     in the header, so we cannot use [Ozstd.Decompressor.decompress_string]
     (which relies on the content-size field). We therefore must call
     the "into buffer" API with a destination buffer that is big enough. *)
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let compressed = compress_stream ~level:3 data in
  let out = Bytes.create (String.length data) in
  let written =
    Ozstd.Decompressor.decompress_string_into_bytes compressed out
  in
  Alcotest.(check int) "written" (String.length data) written;
  Alcotest.(check string) "stream to simple" data (Bytes.to_string out)

let test_incremental_writes () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let buf = Buffer.create 256 in
  let push bs pos len =
    Buffer.add_string buf (Bstr.sub ~off:pos ~len bs |> Bstr.to_string)
  in
  let state = Ozstd.Compressor.State.create ~level:1 () in
  let bs = Bstr.of_string data in
  (* Feed one byte at a time. Note [~pos] and [~size] are *offsets into
     the bigstring* (i.e. [size] is the end offset, not the length). *)
  for i = 0 to Bstr.length bs - 1 do
    Ozstd.Compressor.State.feed ~push state bs i (i + 1) `Continue
  done;
  Ozstd.Compressor.State.finish ~push state;
  let decompressed = decompress_stream (Buffer.contents buf) in
  Alcotest.(check string) "incremental writes" data decompressed

let test_empty_stream () =
  let compressed = compress_stream "" in
  let decompressed = decompress_stream compressed in
  Alcotest.(check string) "empty stream" "" decompressed

let test_flush () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let buf = Buffer.create 256 in
  let push bs pos len =
    Buffer.add_string buf (Bstr.sub ~off:pos ~len bs |> Bstr.to_string)
  in
  let state = Ozstd.Compressor.State.create ~level:1 () in
  let bs = Bstr.of_string data in
  Ozstd.Compressor.State.feed ~push state bs 0 (Bstr.length bs) `Continue;
  Ozstd.Compressor.State.feed ~push state Bstr.empty 0 0 `Flush;
  Alcotest.(check bool) "flush produces output" true (Buffer.length buf > 0);
  Ozstd.Compressor.State.finish ~push state;
  let decompressed = decompress_stream (Buffer.contents buf) in
  Alcotest.(check string) "flush" data decompressed

let test_truncated_stream () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let compressed = compress_stream data in
  let half = String.sub compressed 0 (String.length compressed / 2) in
  try
    let _ = decompress_stream half in
    Alcotest.fail "expected exception"
  with
  | Ozstd.Decompressor.State.Truncated_input -> ()
  | Failure _ -> ()

let test_concatenated_frames () =
  let part1 = "first frame data" in
  let part2 = "second frame data" in
  let c1 = compress_stream part1 in
  let c2 = compress_stream part2 in
  let decompressed = decompress_stream (c1 ^ c2) in
  Alcotest.(check string) "concatenated frames" (part1 ^ part2) decompressed

let test_large_data () =
  let size = (10 * 1024 * 1024) + 37 in
  let data =
    String.init size (fun i ->
        if i mod 512 < 384 then Char.chr (((i * 7) + (i / 256)) mod 256)
        else Char.chr ((i / 4096 mod 26) + 65))
  in
  let compressed = compress_stream ~level:1 data in
  let decompressed = decompress_stream compressed in
  Alcotest.(check string) "large data" data decompressed

let test_gc_stress () =
  let data = String.init 100_000 (fun i -> Char.chr (i mod 256)) in
  let gc_churn () =
    ignore
      (Sys.opaque_identity
         (Array.init 100 (fun i -> String.make 64 (Char.chr (i mod 256)))));
    Gc.compact ()
  in
  let buf = Buffer.create 256 in
  let push bs pos len =
    Buffer.add_string buf (Bstr.sub ~off:pos ~len bs |> Bstr.to_string)
  in
  let state = Ozstd.Compressor.State.create ~level:1 () in
  let bs = Bstr.of_string data in
  let chunk = 512 in
  let pos = ref 0 in
  while !pos < Bstr.length bs do
    let next = min (!pos + chunk) (Bstr.length bs) in
    (* [~pos] = current start, [~size] = end offset (NOT length) *)
    Ozstd.Compressor.State.feed ~push state bs !pos next `Continue;
    gc_churn ();
    pos := next
  done;
  Ozstd.Compressor.State.finish ~push state;
  let compressed = Buffer.contents buf in
  (* decompress with small buffer size: many read+decompress calls *)
  let decompressed = decompress_stream compressed in
  Alcotest.(check string) "gc stress" data decompressed

let test_dictionary () =
  let dict =
    Bstr.of_string (String.init 1000 (fun i -> Char.chr (i mod 256)))
  in
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let compressed =
    Ozstd.Compressor.compress_string ~dictionary:dict ~level:3 data
  in
  let decompressed =
    Ozstd.Decompressor.decompress_string ~dictionary:dict compressed
  in
  Alcotest.(check string) "dictionary" data decompressed

let test_channels () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let tmp_in = Filename.temp_file "Ozstd_test_in" ".txt" in
  let tmp_compressed = Filename.temp_file "Ozstd_test_compressed" ".zst" in
  let tmp_out = Filename.temp_file "Ozstd_test_out" ".txt" in
  Fun.protect
    ~finally:(fun () ->
      Sys.remove tmp_in;
      Sys.remove tmp_compressed;
      Sys.remove tmp_out)
    (fun () ->
      (* write data to tmp_in *)
      let oc = open_out_bin tmp_in in
      output_string oc data;
      close_out oc;
      (* compress tmp_in -> tmp_compressed *)
      let ic = open_in_bin tmp_in in
      let oc = open_out_bin tmp_compressed in
      Ozstd.Compressor.compress_channel ~level:3 ic oc;
      close_in ic;
      close_out oc;
      (* decompress tmp_compressed -> tmp_out *)
      let ic = open_in_bin tmp_compressed in
      let oc = open_out_bin tmp_out in
      Ozstd.Decompressor.decompress_channel ic oc;
      close_in ic;
      close_out oc;
      (* read tmp_out *)
      let ic = open_in_bin tmp_out in
      let len = in_channel_length ic in
      let result = really_input_string ic len in
      close_in ic;
      Alcotest.(check string) "channels" data result)

let test_frame_size () =
  let data = String.init 10_000 (fun i -> Char.chr (i mod 256)) in
  let compressed = Ozstd.Compressor.compress_string ~level:3 data in
  let size = Ozstd.Compressor.Frame.uncompressed_size (`String compressed) in
  Alcotest.(check int) "frame size" (String.length data) size

let test_frame_size_bigstring () =
  let data =
    Bstr.of_string (String.init 10_000 (fun i -> Char.chr (i mod 256)))
  in
  let compressed = Ozstd.Compressor.compress_bigstring ~level:3 data in
  let size = Ozstd.Compressor.Frame.uncompressed_size (`Bigstring compressed) in
  Alcotest.(check int) "frame size bigstring" (Bstr.length data) size

let test_decompress_into () =
  let data = "Hello, Zstandard!" in
  let compressed = Ozstd.Compressor.compress_string ~level:3 data in
  let out = Bytes.create (String.length data) in
  let written =
    Ozstd.Decompressor.decompress_string_into_bytes compressed out
  in
  Alcotest.(check int) "written" (String.length data) written;
  Alcotest.(check string) "content" data (Bytes.to_string out)

let test_compress_into () =
  let data = "Hello, Zstandard!" in
  let bound = Ozstd.Bindings_intf.compress_bound (String.length data) in
  let out = Bytes.create bound in
  let written = Ozstd.Compressor.compress_string_into ~level:3 data out in
  let compressed = Bytes.sub_string out 0 written in
  let decompressed = Ozstd.Decompressor.decompress_string compressed in
  Alcotest.(check string) "compress into" data decompressed

let test_already_closed () =
  let data = "Hello" in
  let compressed = compress_stream data in
  let bs = Bstr.of_string compressed in
  let state = Ozstd.Decompressor.State.create () in
  let push _ _ _ = () in
  Ozstd.Decompressor.State.feed ~push state bs 0 (Bstr.length bs);
  Ozstd.Decompressor.State.finish state;
  try
    Ozstd.Decompressor.State.feed ~push state bs 0 (Bstr.length bs);
    Alcotest.fail "expected Already_closed"
  with Ozstd.Decompressor.State.Already_closed -> ()

(* ------------------------------------------------------------------ *)
(* Test runner                                                        *)
(* ------------------------------------------------------------------ *)

let () =
  Alcotest.run "Ozstd"
    [
      ("version", [ Alcotest.test_case "version" `Quick test_version ]);
      ( "one-shot string",
        [
          Alcotest.test_case "roundtrip" `Quick test_string_roundtrip;
          Alcotest.test_case "compression levels" `Quick test_compression_levels;
        ] );
      ( "one-shot bigstring",
        [ Alcotest.test_case "roundtrip" `Quick test_bigstring_roundtrip ] );
      ( "streaming",
        [
          Alcotest.test_case "roundtrip" `Quick test_stream_roundtrip;
          Alcotest.test_case "simple to stream" `Quick test_simple_to_stream;
          Alcotest.test_case "stream to simple" `Quick test_stream_to_simple;
          Alcotest.test_case "incremental writes" `Quick test_incremental_writes;
          Alcotest.test_case "empty stream" `Quick test_empty_stream;
          Alcotest.test_case "flush" `Quick test_flush;
          Alcotest.test_case "truncated stream" `Quick test_truncated_stream;
          Alcotest.test_case "concatenated frames" `Quick
            test_concatenated_frames;
          Alcotest.test_case "large data" `Quick test_large_data;
          Alcotest.test_case "gc stress" `Quick test_gc_stress;
        ] );
      ("dictionary", [ Alcotest.test_case "roundtrip" `Quick test_dictionary ]);
      ("channels", [ Alcotest.test_case "roundtrip" `Quick test_channels ]);
      ( "frame",
        [
          Alcotest.test_case "string size" `Quick test_frame_size;
          Alcotest.test_case "bigstring size" `Quick test_frame_size_bigstring;
        ] );
      ( "into buffer",
        [
          Alcotest.test_case "string to bytes" `Quick test_decompress_into;
          Alcotest.test_case "compress into" `Quick test_compress_into;
        ] );
      ( "errors",
        [ Alcotest.test_case "already closed" `Quick test_already_closed ] );
    ]
