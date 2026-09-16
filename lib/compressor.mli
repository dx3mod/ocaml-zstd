(** Zstandard compression module.

    Provides one-shot and streaming APIs for data compression. *)

(** Compression context. *)
module Context : sig
  type t

  val create : unit -> t
  (** [create ()]

      Creates a new compression context. *)

  val set_compression_level : t -> int -> unit
  (** [set_compression_level context level]

      Sets the compression level to [context]. *)

  val load_dictionary : t -> Dictionary.t -> unit
  (** [load_dictionary context dictionary]

      Loads [dictionary] into [context]. *)
end

(** Metadata for compressed data. *)
module Frame : sig
  type t = [ `Bigstring of Bstr.t | `String of string ]

  val uncompressed_size : t -> int
  (** [uncompressed_size frame]

      Returns the original uncompressed size of the data represented by [frame].
  *)
end

(** {1 One-shot compressing} *)

val compress_bigstring :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t
(** [compress_bigstring ?context ?dictionary ~level uncompressed_bytes] *)

val compress_string :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  string
(** [compress_string ?context ?dictionary ~level uncompressed_bytes] *)

val compress_channel :
  ?dictionary:Dictionary.t -> level:int -> in_channel -> out_channel -> unit
(** [compress_string ?dictionary ~level ic oc] *)

(** {2 Into buffer} *)

val compress_bigstring_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t ->
  int
(** [compress_bigstring_into ?context ?dictionary ~level uncompressed_bytes
     compressed_destination_buffer] *)

val compress_string_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  bytes ->
  int
(** [compress_string_into ?context ?dictionary ~level uncompressed_bytes
     compressed_destination_buffer] *)

(** {1 Incremental compressing} *)

(** A compression stream module for incremental compression of data chunks. *)
module Stream : sig
  type t

  (** {2 Constructions} *)

  val create : ?dictionary:Dictionary.t -> ?level:int -> unit -> t
  (** [create ?dictionary ?level ()]

      Creates a new compression stream. *)

  val of_context : Context.t -> t
  (** [of_context context]

      Creates a compression stream from the existing compression context. *)

  (** {2 Compression} *)

  exception Already_closed

  val compress :
    in_buffer:Io_buffer.t ->
    out_buffer:Io_buffer.t ->
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
  (** [in_size ()]

      Returns the recommended size for the input compression buffer. *)

  val out_size : unit -> int
  (** [out_size ()]

      Returns the recommended size for the output compression buffer. *)
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

  val feed :
    output:(Bstr.t -> int -> int -> unit) ->
    t ->
    Bstr.t ->
    int ->
    int ->
    [< `Continue | `End | `Flush ] ->
    unit
  (** [feed ~output state buffer position size directive]

      Compresses the data in [buffer] starting at [position] with length [size],
      and feeds the compressed result to the [output] function.

      The [directive] controls the flushing behavior of the stream. *)

  val finish : output:(Bstr.t -> int -> int -> unit) -> t -> unit
  (** [finish ~output state]

      Is similar to {!feed} function, but constrained to the [`End] directive.
  *)
end
