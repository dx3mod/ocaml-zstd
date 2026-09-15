type t = private { buffer : Bstr.t; position : int; size : int }

val create : int -> t
val make : ?pos:int -> ?size:int -> Bstr.t -> t
val is_empty : t -> bool
val empty : t
val length : t -> int
