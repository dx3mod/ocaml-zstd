(** An I/O buffer module that stores a view of data chunks for later compression
    and decompression. *)

type t = private { buffer : Bstr.t; position : int; size : int }

val create : int -> t
(** [create size]

    Allocates an I/O buffer containing a bigstring of [size] bytes. *)

val make : ?pos:int -> ?size:int -> Bstr.t -> t
(** [make ?pos? ?size? buffer]

    Creates an I/O buffer from an existing buffer.

    @param pos Starting position. Defaults to [0].
    @param size Number of bytes to use. Defaults to the size of [buffer]. *)

val is_empty : t -> bool
(** [is_empty io_buffer]

    Returns [true] if [io_buffer] is empty, and [false] otherwise.*)

val length : t -> int
(** [length io_buffer]

    Returns the number of bytes remaining in [io_buffer], i.e. the distance from
    its current position to its end. This is equivalent to [size - pos]. *)

val empty : t
(** [empty] is a preallocated I/O buffer backed by an empty buffer. *)
