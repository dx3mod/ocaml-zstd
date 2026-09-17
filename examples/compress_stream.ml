let uncompressed_buffer = Bstr.of_string "hello world peace"
let stream = Ozstd.Compressor.Stream.create ()

let in_buffer = Ozstd.Io_buffer.make uncompressed_buffer
and out_buffer = Ozstd.Io_buffer.create @@ Ozstd.Decompressor.Stream.out_size ()

let _step =
  Ozstd.Compressor.Stream.compress ~in_buffer ~out_buffer stream `Flush
