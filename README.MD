<p>
  <img src="https://i.ibb.co/LXfsM8S3/logos-001-2.png" width="250">
</p>

A thin, modern OCaml binding to the [Zstandard] compression library. It exposes the common one-shot and streaming APIs of the reference C implementation through a small, idiomatic interface.

**Features**

- One-shot and streaming compression and decompression of string and bigstrings.
- Reusable compression and decompression contexts.
- A low-level `Stream` API where you manage the buffers yourself, and a
  high-level `State` API that pushes output through a callback.

This project is a hard fork of the unmaintained `zstd` OCaml bindings. The original package offered limited functionality and did not cover even the basic features. It has been fully rewritten and reworked, and is distributed as a separate package because the original maintainers do not merge pull requests.

## Installation

You can install the `ozstd` library using the [OPAM] package manager or any
other method you prefer. If you are using [Dune], please add the `ozstd`
library to your dependencies.

## In use

Everything lives in two modules: `Ozstd.Compressor` and `Ozstd.Decompressor`.
Both offer one-shot and streaming APIs.

### One-shot compression and decompression

For data that fits in memory, there are one-shot functions:

```ocaml
let source = "Contrary to popular belief, Lorem Ipsum is not simply random text."

let compressed = Ozstd.Compressor.compress_string ~level:3 source

let decompressed =
  Ozstd.Decompressor.decompress_string compressed
```

The `level` is a Zstandard quality setting between `1` (fastest) and `22`
(best ratio); `3` is a good default.

Bigstring equivalents are available under the same names:
`compress_bigstring` and `decompress_bigstring`. If you already have a
pre-allocated destination buffer, the `*_into` variants
(`compress_string_into`, `decompress_bigstring_into`, ...) avoid the extra
allocation.

Important: streaming compression does not embed the frame's content size in the
header. Consequently, `Ozstd.Decompressor.decompress_string` cannot be used,
because it relies on the content-size field. Instead, call the "into buffer" API
with a destination buffer large enough to hold the decompressed data.

### Reusing contexts

Compression and decompression contexts hold Zstandard's internal state.
Creating one per call is wasteful; create a context once and reuse it:

```ocaml
let compress_all inputs =
  let context = Ozstd.Compressor.Context.create () in
  List.map (Ozstd.Compressor.compress_string ~context ~level:3) inputs
```

Contexts are mutex-guarded, so they can be shared across threads. A dictionary
loaded onto a context applies to every call that uses it:

```ocaml
let compress_all inputs =
  let context = Ozstd.Compressor.Context.create () in
  Ozstd.Compressor.Context.load_dictionary context dictionary;

  List.map (Ozstd.Compressor.compress_string ~context ~level:3) inputs
```

### Streaming (the `State` API)

Streaming is intended for data that does not fit in memory or arrives in pieces.
`State` is the high-level API: provide a `push` callback and it emits output
chunks as they become available:

```ocaml
let compress_sequence_into_channel seq oc =
  let state = Ozstd.Compressor.State.create () in
  let output = Out_channel.output_bigarray oc in

  let aux chunk =
    Ozstd.Compressor.State.feed
      ~push:output state chunk 0 (Bstr.length chunk) `Continue
  in

  Seq.iter aux seq;
  Ozstd.Compressor.State.finish ~push:output state
```

The `directive` argument (`Continue`, `Flush`, `End`) determines how much the
stream flushes along the way. `State.finish` emits the last part of the frame.

Decompression looks the same; it just has no directive:

```ocaml
let decompress_sequence_into_channel seq oc =
  let state = Ozstd.Decompressor.State.create () in
  let output = Out_channel.output_bigarray oc in

  let aux chunk =
    Ozstd.Decompressor.State.feed
      ~push:output state chunk 0 (Bstr.length chunk)
  in

  Seq.iter aux seq;
  Ozstd.Decompressor.State.finish state
```

### Streaming (the `Stream` API)

`Stream` is the more lower-level API, for when you want to supply the buffers
yourself. You give it input and output `Io_buffer`s and it reports how much work
it did:

```ocaml
let stream = Ozstd.Decompressor.Stream.create ()

let in_buffer = Ozstd.Io_buffer.make compressed_buffer
and out_buffer = Ozstd.Io_buffer.create @@ Ozstd.Decompressor.Stream.out_size ()

let (~remaining, ~consumed, ~decompressed) =
  Ozstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
```

The triple reports how many bytes remain in the input, how many were read, and
how many were written to the output. Keep calling it, refilling `in_buffer` and
emptying `out_buffer`, until all data has been processed.
`Ozstd.Compressor.Stream.compress` works the same way.

## Limitations and partial bindings coverage

These bindings cover a substantial subset of the [Zstandard] C API, but not all
of it.

**What is covered**

- One-shot compression and decompression of `string` and `Bstr.t`, with or
  without a pre-created context and/or dictionary, plus into-buffer variants.
- Streaming compression/decompression through `Stream` (via `Io_buffer`) and
  the higher-level `State` modules, and channel helpers built on top of them.
- Reusable `Context`s (wrapped `Ozstd_CCtx`/`Ozstd_DCtx`), mutex-guarded so they
  can be shared across threads (though not in parallel).
- Loading user-provided dictionaries into contexts
  (`Ozstd_*CCtx_loadDictionary`), and reading the stored frame size
  (`Ozstd_getFrameContentSize`).

**What is not covered**

- **Advanced parameters** – only the compression `level` and a decompression
  `size_limit` are exposed. Tuning knobs such as `Ozstd_c_windowLog`,
  `Ozstd_c_chainLog`, `Ozstd_c_hashLog`, `Ozstd_c_targetLength`, long-distance
  matching, and writing checksums or content-size flags are not available.
- **Dictionary training** – dictionaries can be *used* but not *created*: there
  is no binding for the `ZDICT_*` API, so `Dictionary.t` is just a raw `Bstr.t`
  and there is no way to train a dictionary from a sample set.
- **Compiled dictionaries and pledged sizes** – `Ozstd_CDict`/`Ozstd_DDict`,
  `Ozstd_CCtx_setPledgedSrcSize`, and `Ozstd_compress2` are not wrapped; raw or
  experimental APIs (`Ozstd_compressSequences`, `Ozstd_getSequences`, block
  operations, ...) are missing as well.
- **Multithreading** – the `Ozstd_*MT`/worker-based parallel compression API is
  not bound at all; everything runs single-threaded.

## License

The project is licensed under [MIT](./LICENSE). You are free to use it. Pull
requests are welcome.

[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build