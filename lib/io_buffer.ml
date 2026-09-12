type t = { buffer : Bstr.t; mutable position : int; mutable size : int }

let make ?size ?position buffer =
  {
    buffer;
    size = Option.(value ~default:(Bstr.length buffer) size);
    position = Option.(value ~default:0 position);
  }

let is_empty { position; size; _ } = position = size
