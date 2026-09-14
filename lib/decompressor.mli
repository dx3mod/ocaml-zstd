(** Zstandard decompression module.

    Provides one-shot functions for decompressing strings and bigstrings values,
    with a streaming API for incremental decompression.

    All functions accept an optional decompression context that may be reused
    across calls to avoid re-allocating internal state, as well as an optional
    {!Dictionary.t} that must match the one used during compression. *)

module Context : sig
  (** A reusable decompression context. Reusing one across calls avoids
      re-allocating Zstandard's internal state, which is beneficial when
      decompressing many values in a row. *)

  type t

  val create : unit -> t
  (** [create ()] returns a fresh decompression context. *)
end

(** {1 One-shot API} *)

val decompress_string_into_bytes :
  ?context:Context.t -> ?dictionary:Dictionary.t -> string -> bytes -> int
(** [decompress_string_into_bytes ?context ?dictionary compressed_string
     uncompressed_output_bytes] decompresses [compressed_string] into
    [uncompressed_output_bytes] and returns the number of bytes written. *)

val decompress_string :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  original_size:int ->
  string ->
  string
(** [decompress_string ?context ?dictionary ~original_size compressed_string]
    decompresses [compressed_string] and returns the decompressed data as a
    string. [original_size] must be the exact size of the decompressed data.

    This is a convenience wrapper around {!decompress_string_into_bytes} that
    allocates the output buffer. *)

val decompress_bigstring_into :
  ?context:Context.t -> ?dictionary:Dictionary.t -> Bstr.t -> Bstr.t -> int
(** [decompress_bigstring_into ?context ?dictionary compressed_bigstring
     uncompressed_output_bigstring] decompresses [compressed_bigstring] into
    [uncompressed_output_bigstring] and returns the number of bytes written. *)

val decompress_bigstring :
  ?context:Context.t ->
  ?dictionary:Dictionary.t ->
  original_size:int ->
  Bstr.t ->
  Bstr.t
(** [decompress_bigstring ?context ?dictionary ~original_size
     compressed_bigstring] decompresses [compressed_bigstring] and returns a
    freshly allocated bigstring holding the decompressed data. [original_size]
    must be the exact size of the decompressed data.

    This is a convenience wrapper around {!decompress_bigstring_into} that
    allocates the output buffer. *)

(** {1 Streaming API} *)

(** Incremental decompression. *)
module Stream : sig
  type t
  (** A streaming decompression state. *)

  val create : unit -> t
  (** [create ()] returns a fresh streaming state. *)

  val decompress :
    in_buffer:Io_buffer.t ->
    out_buffer:Io_buffer.t ->
    t ->
    (remaining:int * consumed:int * decompressed:int)
  (** [decompress ~in_buffer ~out_buffer stream] feeds the pending compressed
      input from [in_buffer] through the decompressor, appending output to
      [out_buffer].

      The returned triple reports:

      - [remaining]: bytes in [in_buffer] that were not consumed;
      - [consumed]: total bytes read from [in_buffer] by this call;
      - [decompressed]: total bytes appended to [out_buffer] by this call.

      Repeat calls (resupplying input or draining output as needed) until the
      whole compressed stream has been processed. *)
end
