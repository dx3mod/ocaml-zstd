# zstd

A thin and modern OCaml bindings to [Zstandard] compression library.

## Quick start

You can install the `zstd` library using the [OPAM] package manager or any
other method you prefer. If you are using [Dune], please add the `zstd`
library to your dependencies.

## In use

The library offers a small collection of abstractions for compressing and
decompressing data. They are exposed as two modules: `Zstd.Compressor` and
`Zstd.Decompressor`, each providing one-shot and streaming API.

### One-shot compression and decompression

For values that fit comfortably in memory, use one-shot functions.

```ocaml
let source = "Contrary to popular belief, Lorem Ipsum is not simply random text."

let compressed = Zstd.Compressor.compress_string ~level:3 source

let decompressed =
  Zstd.Decompressor.decompress_string
    ~original_size:(String.length source) compressed
```

The `level` is a Zstandard quality setting between `1` (fastest) and `22`
(best ratio); `3` is a good default. When decompressing you must pass
`~original_size`, the exact number of bytes of the original data.

Equivalent functions for bigstrings are available under the same names:
`compress_bigstring` and `decompress_bigstring`.

### Reusing contexts

When compressing or decompressing many values, create a context once and
reuse it across calls instead of allocating a fresh one every time.

```ocaml
let compress_all inputs =
  let context = Zstd.Compressor.Context.create () in
  List.map (Zstd.Compressor.compress_string ~context ~level:3) inputs
```

Reusing a context avoids re-allocating Zstandard's internal state on each
call.

### Streaming compression

Use the streaming API when you want to process the input incrementally and
control how output is flushed.

```ocaml
let compress_streaming uncompressed_bigstring =
  let stream = Zstd.Compressor.Stream.create () in
  let in_buffer = Zstd.Io_buffer.make uncompressed_bigstring in
  let out_buffer = Zstd.Io_buffer.make (Bstr.create 4096) in

  let (~remaining, ~consumed, ~compressed) =
    Zstd.Compressor.Stream.compress ~in_buffer ~out_buffer stream `Flush
  in

  Bstr.sub ~off:0 ~len:compressed out_buffer.buffer
```

The returned triple reports how many bytes are still pending in the input buffer, how many were consumed, and how many compressed bytes were written to the output buffer. The directive controls flushing:

- `` `Continue`` — process input without forcing output, letting the compressor buffer data for better ratios.
- `` `Flush`` — flush everything consumed so far into the output buffer.
- `` `End`` — signal the end of the stream and flush remaining data.

### Streaming decompression

The decompression stream works the same way. Give it a compressed buffer
and an output decompressed buffer.

```ocaml
let decompress_streaming compressed_bigstring =
  let stream = Zstd.Decompressor.Stream.create () in
  let in_buffer = Zstd.Io_buffer.make compressed_bigstring in
  let out_buffer = Zstd.Io_buffer.make (Bstr.create 4096) in

  let (~remaining, ~consumed, ~decompressed) =
    Zstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
  in

  Bstr.sub ~off:0 ~len:decompressed out_buffer.buffer
```

The returned triple reports how many compressed bytes remain in the input compressed buffer, how many were read, and how many were written to the output decompressed buffer.

## License

The project is licensed under [the BSD3 License](./LICENSE), which allows
for all permissions. Just use it and enjoy yourself without fear. We are
always open to pull requests!

[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build