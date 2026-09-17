type t = { buffer : Bstr.t; pos : int; size : int }

let create size = { buffer = Bstr.create size; pos = 0; size }

let make ?pos ?size buffer =
  let size = Option.value ~default:(Bstr.length buffer) size in
  let pos = Option.value ~default:0 pos in

  assert (size <= Bstr.length buffer && pos <= size);

  { buffer; pos; size }

let is_empty { pos; size; _ } = pos = size
let empty = { buffer = Bstr.empty; pos = 0; size = 0 }
let length { pos; size; _ } = size - pos
