let compressed_buffer =
  Zstd.Compressor.compress_bigstring ~level:3
    Bstr.(of_string "hello world peace")

let uncompressed_buffer = Bstr.create 100
let stream = Zstd.Decompressor.Stream.create ()

let in_buffer = Zstd.Io_buffer.make compressed_buffer
and out_buffer = Zstd.Io_buffer.make uncompressed_buffer

let _step = Zstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
