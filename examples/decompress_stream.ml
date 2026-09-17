let compressed_buffer =
  Ozstd.Compressor.compress_bigstring ~level:3
    Bstr.(of_string "hello world peace")

let stream = Ozstd.Decompressor.Stream.create ()

let in_slice = Slice_bstr.make compressed_buffer
and out_slice = Slice_bstr.create @@ Ozstd.Decompressor.Stream.out_size ()

let _step = Ozstd.Decompressor.Stream.decompress ~in_slice ~out_slice stream
