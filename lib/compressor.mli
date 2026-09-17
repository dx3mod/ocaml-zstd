(** Zstandard compression module.

    The module offers both one-shot and streaming APIs for compressing data. *)

(** A reusable compression context. *)
module Context : sig
  type t

  val create : unit -> t
  (** [create ()] allocates a new compression context. *)

  val set_compression_level : t -> int -> unit
  (** [set_compression_level context level] sets the compression level for
      [context]. *)

  val load_dictionary : t -> Dictionary.t -> unit
  (** [load_dictionary context dictionary] loads [dictionary] into [context]. *)
end

(** Metadata for compressed data. *)
module Frame : sig
  type t = [ `Bigstring of Bstr.t | `String of string ]

  val uncompressed_size : t -> int
  (** [uncompressed_size frame] returns the original uncompressed size of the
      data in [frame]. *)
end

(** {1 One-shot compressing} *)

val compress_bigstring :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t
(** [compress_bigstring ?context ?dictionary ~level bigstring]

    Compresses [bigstring] and returns a compressed data as a new bigstring. *)

val compress_string :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  string
(** [compress_string ?context ?dictionary ~level string]

    Compresses [string] and returns a compressed data as a new string.*)

val compress_channel :
  ?dictionary:Dictionary.t -> level:int -> in_channel -> out_channel -> unit
(** [compress_string ?dictionary ~level ic oc]

    Compresses data from [ic] channel to [oc] channel. *)

(** {2 Into buffer} *)

val compress_bigstring_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t ->
  int
(** [compress_bigstring_into ?context ?dictionary ~level src dst]

    Compresses [src] bigstring into [dst] bigstring buffer.

    @return A number of bytes written. *)

val compress_string_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  bytes ->
  int
(** [compress_string_into ?context ?dictionary ~level src dst]

    Compresses [src] string into [dst] bytes buffer.

    @return A number of bytes written *)

(** {1 Incremental compressing} *)

(** The compression stream module for incremental compression. *)
module Stream : sig
  type t

  exception Already_closed
  (** Raised when trying to compress a closed stream. *)

  val create : ?dictionary:Dictionary.t -> ?level:int -> unit -> t
  (** [create ?dictionary ?level ()]

      Creates a new compression stream. *)

  val of_context : Context.t -> t
  (** [of_context context]

      Creates a compression stream from the existing compression [context]. *)

  val close : t -> unit
  (** [finish ()]

      Close the compression stream.

      @raise Already_closed *)

  (** {2 Compression} *)

  val compress :
    in_slice:Slice_bstr.t ->
    out_slice:Slice_bstr.t ->
    t ->
    [< `Continue | `End | `Flush ] ->
    (remaining:int * consumed:int * compressed:int)
  (** [compress ~in_buffer ~out_buffer stream mode]

      Compresses bytes from [in_buffer] into [out_buffer] buffer.

      The [mode] argument controls the flushing behavior of the stream.

      @return
        A labeled triple [(~remaining, ~consumed, ~compressed)] where:
        - [remaining] is the number of bytes remaining in the source;
        - [consumed] is the number of bytes consumed from [in_buffer];
        - [compressed] is the number of compressed bytes written to
          [out_buffer].

      @raise Already_closed If the stream was [`End]'ed. *)

  (** {2 Buffers sizes} *)

  val in_size : unit -> int
  (** [in_size ()] returns the recommended size for the input compression
      buffer. *)

  val out_size : unit -> int
  (** [out_size ()] returns the recommended size for the output compression
      buffer. *)
end

(** A compression stream state for feeding bytes during streaming compression.
*)
module State : sig
  type t

  val make : ?out_buf:Bstr.t -> Stream.t -> t
  (** [make ?out_buf stream]

      Creates a compression stream state from an existing compression [stream].
      If [out_buf] is omitted, a default output buffer is allocated. *)

  val create : ?dictionary:Dictionary.t -> ?level:int -> unit -> t
  (** [create ?dictionary ?level ()]

      Creates a new compression stream. *)

  (** {2 Compression} *)

  val feed : t -> Slice_bstr.t -> [< `Continue | `Flush | `End ] -> Slice_bstr.t
  (** [feed state slice directive]

      Compresses [slice] and provides the compressed data as an output slice.
      The [directive] controls the flushing behavior of the stream. *)

  val finish : t -> Slice_bstr.t
  (** [finish state]

      Is similar to {!feed} function, but constrained to the [`End] directive
      and close the stream. *)
end
