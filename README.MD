# zstd

A thin OCaml bindings to [Zstandard] compression library. 

## Quick start

You can install the `zstd` library using the [OPAM] package manager or any other method you prefer.
If you are using [Dune], please add the `zstd` library to your dependencies.

A small code example:
```ocaml
let zctx = Zstd.Context.create () in 
Zstd.Decompressor.decompress_string zctx ~original_size "..."
```

## License

The project is licensed under [the BSD3 License](./LICENSE), which allows for all permissions.
Just use it and enjoy yourself without fear. We are always open to pull requests!


[Zstandard]: https://github.com/facebook/zstd

[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build