let uncompressed_buffer = Bstr.of_string "hello world peace"
let stream = Zstd.Compressor.Stream.create ()

let in_buffer = Zstd.Io_buffer.make uncompressed_buffer
and out_buffer = Zstd.Io_buffer.create @@ Zstd.Decompressor.Stream.out_size ()

let _step = Zstd.Compressor.Stream.compress ~in_buffer ~out_buffer stream `Flush
