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
  and step = { remaining : int; compressed : int; written : int }

  val create : unit -> t
  val of_context : Context.t -> t
  val make : ?context:Context.t -> unit -> t

  val compress :
    into:Bstr.t -> t -> Bstr.t -> [ `Continue | `Flush | `End ] -> step
end
