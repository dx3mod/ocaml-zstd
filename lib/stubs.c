#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/bigarray.h>

#include <string.h>
#include <zstd.h>

////////////////////////////////////////////////////////////////////////

CAMLextern void caml_enter_blocking_section(void);
CAMLextern void caml_leave_blocking_section(void);

////////////////////////////////////////////////////////////////////////

void custom_finalize_zstd_cctx_ops(value);

static struct custom_operations zstd_cctx_ops = {
    "zstd.CCtx_s",
    custom_finalize_zstd_cctx_ops,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default};

#define Zstd_cctx_val(v) (*((ZSTD_CCtx **)Data_custom_val(v)))

void custom_finalize_zstd_cctx_ops(value cctx)
{
  ZSTD_freeCCtx(Zstd_cctx_val(cctx));
}

CAMLprim value caml_create_zstd_cctx_s(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(cctx_val);

  ZSTD_CCtx *cctx = ZSTD_createCCtx();

  if (cctx == NULL)
    caml_failwith("create_zstd_cctx_s have NULL");

  cctx_val = caml_alloc_custom(&zstd_cctx_ops, sizeof(ZSTD_CCtx *), 0, 1);
  Zstd_cctx_val(cctx_val) = cctx;

  CAMLreturn(cctx_val);
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_version(value unit)
{
  return Val_int(ZSTD_VERSION_NUMBER);
}

CAMLprim value caml_zstd_compress_bound(value src_size)
{
  return Val_int(ZSTD_COMPRESSBOUND(Int_val(src_size)));
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_compress_bigstring_using_cctx(value cctx, value dict, value src_buf, value src_len, value dst_buf, value dst_len, value level)
{
  CAMLparam5(cctx, dict, src_buf, src_len, dst_buf);
  CAMLxparam2(dst_len, level);

  // caml_enter_blocking_section();

  int result;

  if (Is_some(dict))
    result = ZSTD_compress_usingDict(Zstd_cctx_val(cctx),
                                     Caml_ba_data_val(dst_buf), Int_val(dst_buf), Caml_ba_data_val(src_buf),
                                     Int_val(src_len), String_val(Some_val(dict)), caml_string_length(Some_val(dict)), Int_val(level));

  else
    result = ZSTD_compressCCtx(Zstd_cctx_val(cctx),
                               Caml_ba_data_val(dst_buf), Int_val(dst_buf), Caml_ba_data_val(src_buf),
                               Int_val(src_len), Int_val(level));

  // caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_bigstring_using_cctx_bytecode(value *argv, int argn)
{
  return caml_zstd_compress_bigstring_using_cctx(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}

CAMLprim value caml_zstd_compress_string_using_cctx(value cctx, value dict, value src_str, value dst_bytes, value level)
{
  CAMLparam5(cctx, dict, src_str, dst_bytes, level);

  int result;

  caml_enter_blocking_section();
  if (Is_some(dict))
    result = ZSTD_compress_usingDict(Zstd_cctx_val(cctx),
                                     Bytes_val(dst_bytes), caml_string_length(dst_bytes), String_val(src_str),
                                     caml_string_length(src_str), String_val(dict), caml_string_length(dict), Int_val(level));

  else
    result = ZSTD_compressCCtx(Zstd_cctx_val(cctx),
                               Bytes_val(dst_bytes), caml_string_length(dst_bytes), String_val(src_str),
                               caml_string_length(src_str), Int_val(level));
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_decompress_string(value dict, value bytes, value string)
{
  CAMLparam3(dict, bytes, string);

  // NOTE: it's blocking the OCaml runtime
  int result;

  if (Is_some(dict))
    result = ZSTD_decompress(
        Bytes_val(bytes), caml_string_length(bytes), String_val(string),
        caml_string_length(string));

  else
    result = ZSTD_decompress(
        Bytes_val(bytes), caml_string_length(bytes), String_val(string),
        caml_string_length(string));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_decompress_bigstring(value dict, value src_buf, value src_len, value dst_buf, value dst_len)
{
  CAMLparam5(dict, src_buf, src_len, dst_buf, dst_len);

  caml_enter_blocking_section();
  int result = ZSTD_decompress(
      Caml_ba_data_val(dst_buf), Int_val(dst_len),
      Caml_ba_data_val(src_buf), Int_val(src_len));
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}