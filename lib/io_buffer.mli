type t = {
  buffer : Bstr.t;  (** The underlying byte region (source or destination). *)
  mutable position : int;  (** Current offset: bytes consumed or produced. *)
  mutable size : int;
      (** End of the region (for input) or its capacity (for output). *)
}
(** A byte buffer cursor used to model Zstandard input and output buffers.

    This type mirrors the layout of the Zstandard C API buffer structures
    ([ZSTD_inBuffer] and [ZSTD_outBuffer]), which share the same shape: a
    pointer to a byte region, a total [size], and a [position] that is advanced
    as the buffer is consumed or filled.

    A single OCaml type is used for both directions:

    - as an {i input} buffer, [buffer] holds compressed (or to-be-compressed)
      bytes that are read starting at [position] and up to [size];
    - as an {i output} buffer, [buffer] is the destination region, [position] is
      the number of bytes written so far, and [size] is its capacity.

    In both cases [position] is monotonically advanced towards [size], and the
    cursor is exhausted once [is_empty] returns [true].

    Because the fields are exposed as mutable, several values of type {!t} may
    alias the same underlying {!Bstr.t}, and invariants normally maintained by
    {!make} can be broken by direct field mutation. Prefer the functions
    provided by this module. *)

val make : ?size:int -> ?position:int -> Bstr.t -> t
(** [make ?size ?position buffer] creates a new buffer cursor over [buffer].

    @param size
      exclusive upper bound of the view into [buffer]. Defaults to
      [Bstr.length buffer].
    @param position initial offset. Defaults to [0].

    @raise Invalid_argument
      if [size] or [position] is out of bounds for [buffer], or if
      [position > size]. *)

val is_empty : t -> bool
(** [is_empty t] is [true] iff [t] has no remaining work, i.e. iff
    [t.position = t.size].

    For an input buffer this means all bytes in the view have been consumed; for
    an output buffer it means the capacity has been filled up to [size]. *)
