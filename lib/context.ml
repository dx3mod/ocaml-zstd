type t = { cctx : Bindings.Cctx.t }

let create () = { cctx = Bindings.Cctx.create () }
