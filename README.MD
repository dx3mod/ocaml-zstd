# zstd

A thin OCaml bindings to [Zstandard] compression library. 

## Quick start

You can install the `zstd` library using the [OPAM] package manager or any other method you prefer.
If you are using [Dune], please add the `zstd` library to your dependencies.

### In use

The library offers a small collection of abstractions for compressing and decompressing data in sequential and streaming formats. The names of these abstractions are `Zstd.Compressor` and `Zstd.Decompressor`.

First, you should create a context to compress and decompress your blobs. This is necessary to avoid re-allocation.

```ocaml
let decompressor = Zstd.Decompressor.create ()
(* or *)
let compressor = Zstd.Compressor.create () 
```

Next, you can use all the available functions.

```ocaml
let source = {| Contrary .... section 1.10.32. |} in 

Zstd.Compressor.compress_string compressor ~level:0 source 
|> Zstd.Decompressor.decompress_string 
    ~original_size:String.(length source) decompressor
```

## License

The project is licensed under [the BSD3 License](./LICENSE), which allows for all permissions.
Just use it and enjoy yourself without fear. We are always open to pull requests!


[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build