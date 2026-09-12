# zstd

A thin and modern OCaml bindings to [Zstandard] compression library. 

## Quick start

You can install the `zstd` library using the [OPAM] package manager or any other method you prefer.
If you are using [Dune], please add the `zstd` library to your dependencies.

### In use

The library offers a small collection of abstractions for compressing and decompressing data in sequential and streaming formats. The names of these abstractions are `Zstd.Compressor` and `Zstd.Decompressor`.

```ocaml
let source = {| Contrary .... section 1.10.32. |} in 

Zstd.Compressor.compress_string ~level:0 source 
|> Zstd.Decompressor.decompress_string ~original_size:String.(length source)
(* - : string = " Contrary .... section 1.10.32. " *)
```

You may also want to consider using the streaming API. For these exists `Decompressor.Stream` and `Compressor.Stream` modules.

```ocaml
let stream = Zstd.Decompressor.Stream.create ()

and in_buffer = Zstd.Io_buffer.make compressed_buffer
and out_buffer = Zstd.Io_buffer.make uncompressed_buffer in

Zstd.Decompressor.Stream.decompress ~in_buffer ~out_buffer stream
```

## License

The project is licensed under [the BSD3 License](./LICENSE), which allows for all permissions.
Just use it and enjoy yourself without fear. We are always open to pull requests!

[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build