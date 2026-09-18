<p>
  <img src="https://i.ibb.co/LXfsM8S3/logos-001-2.png" width="250">
</p>

A small, modern OCaml binding to [Zstandard]. It wraps the common one-shot and streaming C APIs in a simple, idiomatic interface.

**Features**

- One-shot and streaming compression/decompression for strings and bigstrings.
- Reusable compression and decompression contexts.
- Low-level `Stream` API for manual buffers, and high-level `State` API for slice handling.

## Installation

Install `ozstd` with [OPAM] or another method. If you use [Dune], add `ozstd` to your dependencies.

## In use

Everything is in `Ozstd.Compressor` and `Ozstd.Decompressor`.

### One-shot compression and decompression

For data that fits in memory:

```ocaml
let source = "Contrary to popular belief, Lorem Ipsum is not simply random text."

let compressed = Ozstd.Compressor.compress_string ~level:3 source

let decompressed =
  Ozstd.Decompressor.decompress_string compressed
```

`level` is a Zstandard quality setting from `1` (fastest) to `22` (best ratio); `3` is a good default.

Bigstring versions use the same names: `compress_bigstring` and `decompress_bigstring`. The `*_into` variants (`compress_string_into`, `decompress_bigstring_into`, ...) write into a preallocated destination buffer.

Note: streaming compression does not embed the frame content size. So `Ozstd.Decompressor.decompress_string` will not work for it. Use an “into buffer” API with a destination large enough for the decompressed data.

### Reusing contexts

Contexts hold Zstandard’s internal state. Create one once and reuse it:

```ocaml
let compress_all inputs =
  let context = Ozstd.Compressor.Context.create () in
  List.map (Ozstd.Compressor.compress_string ~context ~level:3) inputs
```

Contexts are mutex-guarded, so they can be shared across threads. A dictionary loaded onto a context applies to every call using it:

```ocaml
let compress_all inputs =
  let context = Ozstd.Compressor.Context.create () in
  Ozstd.Compressor.Context.load_dictionary context dictionary;
  List.map (Ozstd.Compressor.compress_string ~context ~level:3) inputs
```

### Streaming: the `State` API

Use this for data that does not fit in memory or arrives in pieces. `State` is the high-level API: feed it input slices and emit output slices.

```ocaml
let compress_sequence_into_channel seq oc =
  let state = Ozstd.Compressor.State.create () in

  let output Slice.{ buf; off; len } = Out_channel.output_bigarray oc buf off len in
  let aux slice =
    Ozstd.Compressor.State.feed state slice `Continue |> output
  in

  Seq.iter aux seq;
  Ozstd.Compressor.State.finish state |> output
```

The directive (`` `Continue ``, `` `Flush ``, `` `End ``) controls how much the stream flushes. `State.finish` emits the last part of the frame.

Decompression is similar, but without a directive:

```ocaml
let decompress_sequence_into_channel seq oc =
  let state = Ozstd.Decompressor.State.create () in

  let output Slice.{ buf; off; len } = Out_channel.output_bigarray oc buf off len in
  let aux slice =
    Ozstd.Decompressor.State.feed state slice |> output
  in

  Seq.iter aux seq
```

### Streaming: the `Stream` API

`Stream` is the lower-level API. You supply the buffers yourself, and it reports how much work it did.

```ocaml
let stream = Ozstd.Decompressor.Stream.create ()

let in_slice = Slice_bstr.make compressed_buffer
and out_slice = Slice_bstr.create (Ozstd.Decompressor.Stream.out_size ())

let (~remaining, ~consumed, ~decompressed) =
  Ozstd.Decompressor.Stream.decompress ~in_slice ~out_slice stream
```

The triple reports bytes remaining in the input, bytes read, and bytes written to the output. Keep calling it, refilling the input buffer and emptying the output buffer, until all data is processed. `Ozstd.Compressor.Stream.compress` works the same way.

## Limitations

These bindings cover a large part of the [Zstandard] C API, but not all of it.

**Covered**

- One-shot compression/decompression of `string` and `Bstr.t`, with optional context and/or dictionary, plus into-buffer variants.
- Streaming compression/decompression via `Stream` and the higher-level `State` modules.
- Reusable, mutex-guarded `Context`s.
- Loading user dictionaries and reading stored frame size.

**Not covered**

- **Advanced parameters** — only compression `level` and decompression `size_limit` are exposed. Tuning knobs, long-distance matching, checksums, and content-size flags are not available.
- **Dictionary training** — dictionaries can be used but not created. There is no `ZDICT_*` binding.
- **Compiled dictionaries and pledged sizes** — `Ozstd_CDict`/`Ozstd_DDict`, `Ozstd_CCtx_setPledgedSrcSize`, and `Ozstd_compress2` are not wrapped. Raw and experimental APIs are also missing.
- **Multithreading** — the `Ozstd_*MT` parallel compression API is not bound; everything runs single-threaded.

## License

Licensed under [MIT](./LICENSE). Pull requests are welcome.

[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build
