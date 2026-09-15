type t = { buffer : Bstr.t; mutable position : int; size : int }

let create size = { buffer = Bstr.create size; position = 0; size }

let make ?pos ?size buffer =
  let size = Option.value ~default:(Bstr.length buffer) size in
  let position = Option.value ~default:0 pos in

  assert (size <= Bstr.length buffer && position <= size);

  { buffer; position; size }

let is_empty { position; size; _ } = position = size

let sub ~off ~len { buffer; position; _ } =
  Bstr.sub ~off:(off + position) ~len buffer
