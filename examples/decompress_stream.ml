let compressed_buffer =
  Zstd.Compressor.compress_bigstring ~level:3
    Bstr.(of_string "hello world peace")

let stream = Zstd.Decompressor.Stream.create ()

let in_buffer = Zstd.Io_buffer.make compressed_buffer
and out_buffer = Zstd.Io_buffer.create @@ Zstd.Decompressor.Stream.out_size ()

let _step = Zstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
