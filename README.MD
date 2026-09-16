<p>
  <img src="https://i.ibb.co/LXfsM8S3/logos-001-2.png" width="250">
</p>

A thin and modern OCaml binding to the [Zstandard] compression library. It
wraps the common one-shot and streaming APIs of the reference C
implementation, exposed through a small, idiomatic surface.

## Features

- One-shot and streaming compression/decompression for `string` and
  bigstring (`Bstr.t`) data.
- Reusable compression and decompression contexts.
- Both a low-level `Stream` API (pull-style, buffer driven) and a
  high-level `State` API (push-style, callback driven).

## Installation

You can install the `zstd` library using the [OPAM] package manager or any
other method you prefer. If you are using [Dune], please add the `zstd`
library to your dependencies.

## In use

The library offers a small collection of abstractions for compressing and
decompressing data. They are exposed as two modules: `Zstd.Compressor` and
`Zstd.Decompressor`, each providing one-shot and streaming APIs.

### One-shot compression and decompression

Values that fit comfortably in memory can be compressed or decompressed
with a single function call:

```ocaml
let source = "Contrary to popular belief, Lorem Ipsum is not simply random text."

let compressed = Zstd.Compressor.compress_string ~level:3 source

let size = Zstd.Compressor.Frame.uncompressed_size (`String compressed)

let decompressed =
  Zstd.Decompressor.decompress_string ~original_size:size compressed
```

The `level` is a Zstandard quality setting between `1` (fastest) and `22`
(best ratio); `3` is a good default. `Frame.uncompressed_size` reads the
original size straight from the frame, so you do not have to track it
yourself.

Bigstring equivalents are available under the same names:
`compress_bigstring` and `decompress_bigstring`. If you already have a
pre-allocated destination buffer, the `*_into` variants
(`compress_string_into`, `decompress_bigstring_into`, ...) avoid the extra
allocation.

### Reusing contexts

Compression and decompression contexts hold Zstandard's internal state.
Creating one per call is wasteful; create a context once and reuse it:

```ocaml
let compress_all inputs =
  let context = Zstd.Compressor.Context.create () in
  List.map (Zstd.Compressor.compress_string ~context ~level:3) inputs
```

Contexts are guarded by a mutex, so a single context can be reused from
several threads without risk. A dictionary can be loaded on a context and
is then applied to every operation:

```ocaml
let context = Zstd.Compressor.Context.create () in
Zstd.Compressor.Context.load_dictionary context dictionary;
let compressed = Zstd.Compressor.compress_string ~context ~level:3 payload
```

### Streaming compression (the `State` API)

When the input arrives incrementally — say from a file, a channel or a
network socket — use streaming. The high-level `State` module takes a
`push` callback and flushes compressed output into it as it becomes
available:

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

The `directive` argument (`Continue`, `Flush` or `End`) controls how
aggressively the stream flushes its internal buffers. `State.finish` is a
`feed` call with the `End` directive, emitting the final frame bytes.

The decompression side works the same way, but without a directive:

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

### Streaming decompression (the `Stream` API)

For finer control — when you want to drive the buffers yourself — the
low-level `Stream` module works on `Io_buffer` views. You supply an `in`
and an `out` buffer and get back how much was consumed and produced:

```ocaml
let stream = Zstd.Decompressor.Stream.create ()

let in_buffer = Zstd.Io_buffer.make compressed_buffer
and out_buffer = Zstd.Io_buffer.create @@ Zstd.Decompressor.Stream.out_size ()

let (~remaining, ~consumed, ~decompressed) =
  Zstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
```

The returned labeled triple reports:

- `remaining` — compressed bytes left in the input buffer;
- `consumed` — bytes read from `in_buffer`;
- `decompressed` — bytes written to `out_buffer`.

Repeat the call, topping up `in_buffer` and draining `out_buffer`, until
the input is fully consumed. `Zstd.Compressor.Stream.compress` follows the
same pattern and additionally takes a `directive`.

## Limitations and partial bindings coverage

This library is a *thin* subset of the [Zstandard] C API. It covers the common
one-shot and streaming paths but deliberately leaves much of the underlying
library unbound.

**What is covered**

- One-shot compression and decompression of `string` and `Bstr.t`, with or
  without a pre-created context and/or dictionary; plus into-buffer variants.
- Streaming compression/decompression through `Stream` (via `Io_buffer`) and
  the higher-level `State` modules, and channel helpers built on top of them.
- Reusable `Context`s (wrapped `ZSTD_CCtx`/`ZSTD_DCtx`), each guarded by a
  mutex so reuse across threads is safe but not parallel.
- Loading user-provided dictionaries into contexts
  (`ZSTD_*CCtx_loadDictionary`), and reading the stored frame size
  (`ZSTD_getFrameContentSize`).

**What is not covered**

- **Advanced parameters** – only the compression `level` and a decompression
  `size_limit` are exposed. Tuning knobs such as `ZSTD_c_windowLog`,
  `ZSTD_c_chainLog`, `ZSTD_c_hashLog`, `ZSTD_c_targetLength`, long-distance
  matching, and writing checksums or content-size flags are unbound.
- **Dictionary training** – dictionaries can be *used* but not *created*: there
  is no binding for the `ZDICT_*` API, so `Dictionary.t` is simply a raw
  `Bstr.t` and there is no way to train a dictionary from a sample set.
- **Compiled dictionaries and pledged sizes** – `ZSTD_CDict`/`ZSTD_DDict`,
  `ZSTD_CCtx_setPledgedSrcSize`, and `ZSTD_compress2` are not wrapped; raw or
  experimental APIs (`ZSTD_compressSequences`, `ZSTD_getSequences`, block
  operations, ...) are likewise absent.
- **Multithreading** – the `ZSTD_*MT`/worker-based parallel compression API is
  not bound at all; everything runs single-threaded.

## License

The project is licensed under [the BSD3 License](./LICENSE), which allows
for all permissions. Just use it and enjoy yourself without fear. We are
always open to pull requests!

[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build