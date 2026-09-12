module Context : sig
  type t

  val create : unit -> t
end

val compress_bigstring :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t

val compress_string :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  string

module Stream : sig
  type t

  val create : unit -> t
  val of_context : Context.t -> t

  val compress :
    in_buffer:Io_buffer.t ->
    out_buffer:Io_buffer.t ->
    t ->
    [ `Continue | `Flush | `End ] ->
    (remaining:int * compressed:int * written:int)
end
