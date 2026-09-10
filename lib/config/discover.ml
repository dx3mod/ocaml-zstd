module C = Configurator.V1

let () =
  C.main ~name:"zstd" @@ fun c ->
  let pkg_config = C.Pkg_config.get c |> Option.get in
  let conf = C.Pkg_config.query pkg_config ~package:"libzstd" |> Option.get in

  C.Flags.write_sexp "c_flags.sexp" conf.cflags;
  C.Flags.write_sexp "c_library_flags.sexp" conf.libs
