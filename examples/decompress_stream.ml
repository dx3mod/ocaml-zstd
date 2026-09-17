let compressed_buffer =
  Ozstd.Compressor.compress_bigstring ~level:3
    Bstr.(of_string "hello world peace")

let stream = Ozstd.Decompressor.Stream.create ()

let in_buffer = Ozstd.Io_buffer.make compressed_buffer
and out_buffer = Ozstd.Io_buffer.create @@ Ozstd.Decompressor.Stream.out_size ()

let _step = Ozstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
