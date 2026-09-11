module Context : sig
  type t

  val create : unit -> t
end

val decompress_string_into_bytes :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  original_size:int ->
  string ->
  bytes ->
  int

val decompress_string :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  original_size:int ->
  string ->
  string

val decompress_bigstring_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  original_size:int ->
  Bstr.t ->
  Bstr.t ->
  int

val decompress_bigstring :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  original_size:int ->
  Bstr.t ->
  Bstr.t

module Stream : sig
  type t
  and step = { remaining : int; consumed : int; decompressed : int }

  val create : unit -> t
  val decompress : into:Bstr.t -> t -> Bstr.t -> step
end
