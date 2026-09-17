(** Zstandard decompression module.

    The module offers both one-shot and streaming APIs for decompressing data.
*)

(** A reusable decompression context. *)
module Context : sig
  type t

  val create : unit -> t
  (** [create ()] allocates a new decompression context. *)

  val set_size_limit : t -> int -> unit
  (** [set_size_limit context size] sets the internal decompression buffer
      [size] limit for [context]. *)

  val load_dictionary : t -> Dictionary.t -> unit
  (** [load_dictionary context dictionary] loads [dictionary] into [context]. *)
end

(** {1 One-shot decompressing} *)

val decompress_bigstring :
  ?context:Context.t -> ?dictionary:Dictionary.t -> Bstr.t -> Bstr.t
(** [decompress_bigstring ?context ?dictionary bigstring]

    Decompresses [bigstring] and returns the uncompressed data as a new
    bigstring. *)

val decompress_string :
  ?context:Context.t -> ?dictionary:Bstr.t -> string -> string
(** [decompress_string ?context ?dictionary string]

    Decompresses [string] and returns the uncompressed data as a new string. *)

val decompress_channel :
  ?dictionary:Dictionary.t ->
  ?size_limit:int ->
  in_channel ->
  out_channel ->
  unit
(** [decompress_channel ic oc]

    Decompresses data from [ic] channel to [oc] channel. *)

(** {2 Into buffer} *)

val decompress_bigstring_into :
  ?context:Context.t -> ?dictionary:Dictionary.t -> Bstr.t -> Bstr.t -> int
(** [compress_bigstring_into ?context ?dictionary src dst]

    Decompresses [src] bigstring into [dst] bigstring buffer.

    @return A number of bytes written. *)

val decompress_string_into_bytes :
  ?context:Context.t -> ?dictionary:Dictionary.t -> string -> bytes -> int
(** [compress_bigstring_into ?context ?dictionary src dst]

    Decompresses [src] string into [dst] bytes buffer.

    @return A number of bytes written. *)

(** {1 Incremental compressing} *)

(** The decompression stream module for incremental decompression. *)
module Stream : sig
  type t

  exception Already_closed
  (** Raised when trying to decompress a closed stream. *)

  val create : ?dictionary:Dictionary.t -> ?size_limit:int -> unit -> t
  (** [create ?dictionary ?size_limit ()]

      Creates a new decompression stream. *)

  val close : t -> unit
  (** [finish ()]

      Close a decompression stream.

      @raise Already_closed *)

  (** {2 Decompression} *)

  val decompress :
    in_slice:Slice_bstr.t ->
    out_slice:Slice_bstr.t ->
    t ->
    (remaining:int * consumed:int * decompressed:int)
  (** [decompress ~in_slice ~out_slice stream]

      Decompresses bytes from [in_slice] into [out_slice] buffer.

      @return
        A labeled triple [(~remaining, ~consumed, ~decompressed)] where:
        - [remaining] is the number of bytes remaining in the source;
        - [consumed] is the number of bytes consumed from [in_slice];
        - [decompressed] is the number of decompressed bytes written to
          [out_slice]. *)

  (** {2 Buffers sizes} *)

  val in_size : unit -> int
  (** [in_size ()] returns the recommended size for the input decompression
      buffer. *)

  val out_size : unit -> int
  (** [out_size ()] returns the recommended size for the output decompression
      buffer. *)
end

(** A decompression stream state for feeding bytes during streaming
    decompression. *)
module State : sig
  type t

  val make : ?out_buf:Bstr.t -> ?stream:Stream.t -> unit -> t
  (** [make ?out_buf ?stream stream]

      Creates a decompression stream state from an existing decompression
      [stream]. If [out_buf] is omitted, a default output buffer is allocated.
  *)

  val create : ?dictionary:Dictionary.t -> ?size_limit:int -> unit -> t
  (** [create ?dictionary ?size_limit ()]

      Creates a new decompression stream. *)

  (** {2 Compression} *)

  val feed : t -> Slice_bstr.t -> Slice_bstr.t
  (** [feed state slice]

      Decompresses [slice] and provides the decompressed data as an output
      slice.

      @raise Already_closed *)
end
