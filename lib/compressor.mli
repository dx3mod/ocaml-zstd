(** Zstandard compression module.

    Provides one-shot functions for compressing strings and bigstrings values
    with a streaming API for incremental compression.

    All functions accept an optional compression [level] (a Zstandard quality
    setting, typically between [1] and [22]) and may reuse a {!Context.t} across
    calls to avoid re-allocating internal state. A {!Dictionary.t} can be
    supplied to improve compression of small or repetitive inputs.

    When [?dictionary] is supplied without [?context], a fresh context is
    allocated internally for that call. Prefer passing a {!Context.t} explicitly
    when compressing many values with the same dictionary. *)

module Context : sig
  (** A reusable compression context. Reusing one across calls avoids
      re-allocating Zstandard's internal state, which is beneficial when
      compressing many values.

      A context is protected by an internal mutex, so the same {!t} may be
      safely shared between domains and threads. *)

  type t

  val create : unit -> t
  (** [create ()] returns a fresh compression context. *)
end

(** A Zstandard frame.

    A compressed representation of data. *)
module Frame : sig
  type t = [ `String of string | `Bigstring of Bstr.t ]

  val uncompressed_size : t -> int
  (** [uncompressed_size frame] returns the decompressed size recorded in the
      header of the compressed [frame]. *)
end

(** {1 One-shot API} *)

val compress_bigstring_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t ->
  int
(** [compress_bigstring_into ?context ?dictionary ~level uncompressed_bigstring
     compressed_output_bigstring] compresses [uncompressed_bigstring] into
    [compressed_output_bigstring] and returns the number of bytes written. *)

val compress_bigstring :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  Bstr.t ->
  Bstr.t
(** [compress_bigstring ?context ?dictionary ~level uncompressed_bigstring]
    compresses [uncompressed_bigstring] and returns a freshly allocated
    bigstring holding the compressed data.

    This is a convenience wrapper around {!compress_bigstring_into} that
    allocates the output buffer. *)

val compress_string_into :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  bytes ->
  int
(** [compress_string_into ?context ?dictionary ~level uncompressed_string
     compressed_output_bytes] compresses [uncompressed_string] into
    [compressed_output_bytes] and returns the number of bytes written.

    The caller is responsible for ensuring that [compressed_output_bytes] is
    large enough to hold the result; see {!compress_string} for a convenience
    wrapper that allocates a suitably sized buffer. *)

val compress_string :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  level:int ->
  string ->
  string
(** [compress_string ?context ?dictionary ~level uncompressed_string] compresses
    [uncompressed_string] and returns the compressed data as a string.

    This is a convenience wrapper around {!compress_string_into} that allocates
    the output buffer. *)

(** {1 Streaming API} *)

(** Incremental compression. *)
module Stream : sig
  type t
  (** A streaming compression state. *)

  val create : unit -> t
  (** [create ()] returns a fresh streaming state. *)

  val of_context : Context.t -> t
  (** [of_context ctx] reuses [ctx] as a streaming state, so that any state it
      has accumulated is carried over. *)

  val in_size : unit -> int
  (** [in_size ()] is the recommended size, in bytes, for the input buffer
      passed to {!compress}. *)

  val out_size : unit -> int
  (** [out_size ()] is the recommended size, in bytes, for the output buffer
      passed to {!compress}. *)

  exception Already_closed
  (** Raised by {!compress} when the stream has already been terminated with
      [`End]. *)

  val compress :
    in_buffer:Io_buffer.t ->
    out_buffer:Io_buffer.t ->
    t ->
    [< `Continue | `End | `Flush ] ->
    (remaining:int * consumed:int * compressed:int)
  (** [compress ~in_buffer ~out_buffer stream directive] feeds the input held in
      [in_buffer] through the compressor, appending output to [out_buffer].

      [directive] controls flushing:

      - [`Continue] processes input without forcing output to be flushed,
        allowing the compressor to buffer data for better ratios.
      - [`Flush] emits all buffered input using an end-of-frame marker without
        closing the stream. Further calls may be made, but any new input begins
        a new frame.
      - [`End] behaves like [`Flush] and additionally marks the stream as
        closed; subsequent calls on the same [stream] raise {!Already_closed}.

      @raise Already_closed if [stream] has already been terminated with [`End].

      The returned triple reports:

      - [remaining]: bytes in [in_buffer] that were not consumed;
      - [consumed]: total bytes consumed from [in_buffer] by this call;
      - [compressed]: total compressed bytes appended to [out_buffer] by this
        call.

      Repeat calls (resupplying input or draining output as needed) until the
      caller's input has been fully consumed and the stream has been ended with
      [`End]. *)
end
