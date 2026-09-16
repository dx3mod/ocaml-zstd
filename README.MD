<p>
  <img src="https://i.ibb.co/LXfsM8S3/logos-001-2.png" width="250">
</p>

A thin and modern OCaml binding to the [Zstandard] compression library. It provides common one-shot and streaming APIs from the reference C implementation, exposing them through a small and idiomatic interface.

## Features

- One-shot and streaming compression and decompression of `string` and `Bstr.t`
  bigstrings.
- Reusable compression and decompression contexts.
- A low-level `Stream` API where you drive the buffers yourself, and a
  high-level `State` API that pushes output through a callback.

## Installation

You can install the `zstd` library using the [OPAM] package manager or any
other method you prefer. If you are using [Dune], please add the `zstd`
library to your dependencies.

## In use

Everything lives in two modules: `Zstd.Compressor` and `Zstd.Decompressor`.
Both offer one-shot and streaming APIs.

### One-shot compression and decompression

For data that fits in memory, there are one-shot functions:

```ocaml
let source = "Contrary to popular belief, Lorem Ipsum is not simply random text."

let compressed = Zstd.Compressor.compress_string ~level:3 source

let decompressed =
  Zstd.Decompressor.decompress_string compressed
```

The `level` is a Zstandard quality setting between `1` (fastest) and `22`
(best ratio); `3` is a good default.

Bigstring equivalents are available under the same names:
`compress_bigstring` and `decompress_bigstring`. If you already have a
pre-allocated destination buffer, the `*_into` variants
(`compress_string_into`, `decompress_bigstring_into`, ...) avoid the extra
allocation.

Important: streaming compression does not embed the frame’s content size in the header. 
Consequently, we cannot use `Zstd.Decompressor.decompress_string`, because it relies 
on the content-size field. We must instead call the “into buffer” API with a destination
 buffer large enough to hold the decompressed data.

### Reusing contexts

Compression and decompression contexts hold Zstandard's internal state.
Creating one per call is wasteful; create a context once and reuse it:

```ocaml
let compress_all inputs =
  let context = Zstd.Compressor.Context.create () in
  List.map (Zstd.Compressor.compress_string ~context ~level:3) inputs
```

Contexts are mutex-guarded, so they can be shared across threads. A dictionary
loaded onto a context applies to every call that uses it:

```ocaml
let context = Zstd.Compressor.Context.create () in
Zstd.Compressor.Context.load_dictionary context dictionary;
let compressed = Zstd.Compressor.compress_string ~context ~level:3 payload
```

### Streaming (the `State` API)

Streaming is for when the data doesn't fit in memory or comes in pieces.
`State` is the high-level API: give it a `push` callback and it hands out
output chunks as they're ready:

```ocaml
let compress_sequence_into_channel seq oc =
  let state = Zstd.Compressor.State.create () in
  let output = Out_channel.output_bigarray oc in
  let aux chunk =
    Zstd.Compressor.State.feed
      ~push:output state chunk 0 (Bstr.length chunk) `Continue
  in
  Seq.iter aux seq;
  Zstd.Compressor.State.finish ~push:output state
```

The `directive` argument (`Continue`, `Flush`, `End`) decides how much the
stream flushes along the way. `State.finish` emits the last of the frame.

Decompression looks the same; it just has no directive:

```ocaml
let decompress_sequence_into_channel seq oc =
  let state = Zstd.Decompressor.State.create () in
  let output = Out_channel.output_bigarray oc in
  let aux chunk =
    Zstd.Decompressor.State.feed
      ~push:output state chunk 0 (Bstr.length chunk)
  in
  Seq.iter aux seq;
  Zstd.Decompressor.State.finish state
```

### Streaming (the `Stream` API)

`Stream` is the lower-level API, for when you want to supply the buffers
yourself. You give it input and output `Io_buffer`s and it tells you how much
work it did:

```ocaml
let stream = Zstd.Decompressor.Stream.create ()

let in_buffer = Zstd.Io_buffer.make compressed_buffer
and out_buffer = Zstd.Io_buffer.create @@ Zstd.Decompressor.Stream.out_size ()

let (~remaining, ~consumed, ~decompressed) =
  Zstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
```

The triple tells you how many bytes remain in the input, how many were read,
and how many were written to the output. Keep calling, refilling `in_buffer`
and emptying `out_buffer`, until it's all gone. `Zstd.Compressor.Stream.compress`
works the same way.

## Limitations and partial bindings coverage

These bindings cover a solid chunk of the [Zstandard] C API, not all of it.

**What is covered**

- One-shot compression and decompression of `string` and `Bstr.t`, with or
  without a pre-created context and/or dictionary; plus into-buffer variants.
- Streaming compression/decompression through `Stream` (via `Io_buffer`) and
  the higher-level `State` modules, and channel helpers built on top of them.
- Reusable `Context`s (wrapped `ZSTD_CCtx`/`ZSTD_DCtx`), mutex-guarded so they
  can be shared across threads (though not in parallel).
- Loading user-provided dictionaries into contexts
  (`ZSTD_*CCtx_loadDictionary`), and reading the stored frame size
  (`ZSTD_getFrameContentSize`).

**What is not covered**

- **Advanced parameters** – only the compression `level` and a decompression
  `size_limit` are exposed. Tuning knobs such as `ZSTD_c_windowLog`,
  `ZSTD_c_chainLog`, `ZSTD_c_hashLog`, `ZSTD_c_targetLength`, long-distance
  matching, and writing checksums or content-size flags are not available.
- **Dictionary training** – dictionaries can be *used* but not *created*: no
  binding for the `ZDICT_*` API, so `Dictionary.t` is just a raw `Bstr.t` and
  there is no way to train a dictionary from a sample set.
- **Compiled dictionaries and pledged sizes** – `ZSTD_CDict`/`ZSTD_DDict`,
  `ZSTD_CCtx_setPledgedSrcSize`, and `ZSTD_compress2` are not wrapped; raw or
  experimental APIs (`ZSTD_compressSequences`, `ZSTD_getSequences`, block
  operations, ...) are missing too.
- **Multithreading** – the `ZSTD_*MT`/worker-based parallel compression API is
  not bound at all; everything runs single-threaded.

## License

The project is licensed under [the BSD3 License](./LICENSE). Just use it and
enjoy yourself without fear. We are always open to pull requests!

[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build