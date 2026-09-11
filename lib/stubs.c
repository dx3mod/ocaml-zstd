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

void custom_finalize_zstd_dctx_ops(value);

static struct custom_operations zstd_dctx_ops = {
    "zstd.DCtx_s",
    custom_finalize_zstd_dctx_ops,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default};

#define Zstd_dctx_val(v) (*((ZSTD_DCtx **)Data_custom_val(v)))

void custom_finalize_zstd_dctx_ops(value dctx)
{
  ZSTD_freeDCtx(Zstd_dctx_val(dctx));
}

CAMLprim value caml_create_zstd_dctx_s(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(dctx_val);

  ZSTD_DCtx *dctx = ZSTD_createDCtx();

  if (dctx == NULL)
    caml_failwith("create_zstd_cctx_s have NULL");

  dctx_val = caml_alloc_custom(&zstd_dctx_ops, sizeof(ZSTD_DCtx *), 0, 1);
  Zstd_dctx_val(dctx_val) = dctx;

  CAMLreturn(dctx_val);
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_compress_bigstring(value src_buf, value src_len, value dst_buf, value dst_len, value level)
{
  CAMLparam5(src_buf, src_len, dst_buf, dst_len, level);

  int result = ZSTD_compress(
      Caml_ba_data_val(dst_buf), Int_val(dst_len), Caml_ba_data_val(src_buf),
      Int_val(src_len), Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_bigstring_with_context(value context, value src_buf, value src_len, value dst_buf, value dst_len, value level)
{
  CAMLparam5(src_buf, src_len, dst_buf, dst_len, level);
  CAMLxparam1(context);

  int result = ZSTD_compressCCtx(Zstd_cctx_val(context),
                                 Caml_ba_data_val(dst_buf), Int_val(dst_len), Caml_ba_data_val(src_buf),
                                 Int_val(src_len), Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_bigstring_with_context_bytecode(value *argv, int argn)
{
  return caml_zstd_compress_bigstring_with_context(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim value caml_zstd_compress_bigstring_with_context_and_dictionary(value context, value dictionary, value src_buf, value src_len, value dst_buf, value dst_len, value level)
{
  CAMLparam5(src_buf, src_len, dst_buf, dst_len, level);
  CAMLxparam2(context, dictionary);

  int result = ZSTD_compress_usingDict(Zstd_cctx_val(context),
                                       Caml_ba_data_val(dst_buf), Int_val(dst_len), Caml_ba_data_val(src_buf),
                                       Int_val(src_len), String_val(dictionary), caml_string_length(dictionary), Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_bigstring_with_context_and_dictionary_bytecode(value *argv, int argn)
{
  return caml_zstd_compress_bigstring_with_context_and_dictionary(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_compress_string(value src_str, value src_len, value dst_bytes, value dst_len, value level)
{
  CAMLparam5(src_len, src_len, dst_bytes, dst_len, level);

  int result = ZSTD_compress(
      Bytes_val(dst_bytes), Int_val(dst_len), String_val(src_str),
      Int_val(src_len), Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_string_with_context(value context, value src_str, value src_len, value dst_bytes, value dst_len, value level)
{
  CAMLparam5(src_len, src_len, dst_bytes, dst_len, level);
  CAMLxparam1(context);

  int result = ZSTD_compressCCtx(Zstd_cctx_val(context),
                                 Bytes_val(dst_bytes), Int_val(dst_len), String_val(src_str),
                                 Int_val(src_len), Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_string_with_context_bytecode(value *argv, int argn)
{
  return caml_zstd_compress_string_with_context(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim value caml_zstd_compress_string_with_context_and_dictionary(value context, value dictionary, value src_str, value src_len, value dst_bytes, value dst_len, value level)
{
  CAMLparam5(src_len, src_len, dst_bytes, dst_len, level);
  CAMLxparam2(context, dictionary);

  int result = ZSTD_compress_usingDict(Zstd_cctx_val(context),
                                       Bytes_val(dst_bytes), Int_val(dst_len), String_val(src_str),
                                       Int_val(src_len), String_val(dictionary), caml_string_length(dictionary), Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_compress_string_with_context_and_dictionary_bytecode(value *argv, int argn)
{
  return caml_zstd_compress_string_with_context_and_dictionary(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// DECOMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_decompress_string(value src_str, value dst_bytes, value original_size)
{
  CAMLparam3(src_str, dst_bytes, original_size);

  int result = ZSTD_decompress(Bytes_val(dst_bytes), Int_val(original_size), String_val(src_str), caml_string_length(src_str));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_decompress_string_with_context(value context, value src_str, value dst_bytes, value original_size)
{
  CAMLparam4(context, src_str, dst_bytes, original_size);

  int result = ZSTD_decompressDCtx(Zstd_dctx_val(context), Bytes_val(dst_bytes), caml_string_length(dst_bytes), String_val(src_str), Int_val(original_size));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_decompress_string_with_context_and_dictionary(value context, value dictionary, value src_str, value dst_bytes, value original_size)
{
  CAMLparam5(context, dictionary, src_str, dst_bytes, original_size);

  int result = ZSTD_decompress_usingDict(Zstd_dctx_val(context), Bytes_val(dst_bytes),
                                         caml_string_length(dst_bytes), String_val(src_str), Int_val(original_size),
                                         String_val(dictionary),
                                         caml_string_length(dictionary));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_decompress_bigstring(value src_buf, value dst_buf, value dst_cap, value original_size)
{
  CAMLparam4(src_buf, dst_buf, dst_cap, original_size);

  int result = ZSTD_decompress(Caml_ba_data_val(dst_buf), Int_val(dst_cap), Caml_ba_data_val(src_buf), Int_val(original_size));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_decompress_bigstring_with_context(value context, value src_buf, value dst_buf, value dst_cap, value original_size)
{
  CAMLparam5(context, src_buf, dst_buf, dst_cap, original_size);

  int result = ZSTD_decompressDCtx(
      Zstd_dctx_val(context),
      Caml_ba_data_val(dst_buf), Int_val(dst_cap), Caml_ba_data_val(src_buf), Int_val(original_size));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_decompress_bigstring_with_context_and_dictionary(value context, value dictionary, value src_buf, value dst_buf, value dst_cap, value original_size)
{
  CAMLparam5(context, src_buf, dst_buf, dst_cap, original_size);
  CAMLxparam1(dictionary);

  int result = ZSTD_decompress_usingDict(
      Zstd_dctx_val(context),
      Caml_ba_data_val(dst_buf), Int_val(dst_cap), Caml_ba_data_val(src_buf),
      Int_val(original_size), String_val(dictionary), caml_string_length(dictionary));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_int(result));
}

CAMLprim value caml_zstd_decompress_bigstring_with_context_and_dictionary_bytecode(value *argv, int argn)
{
  return caml_zstd_decompress_bigstring_with_context_and_dictionary(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// STREAM COMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_compress_stream2(value context, value src_buf, value dst_buf, value directive)
{
  CAMLparam4(context, src_buf, dst_buf, directive);
  CAMLlocal1(tup);

  ZSTD_inBuffer input = {
      .src = Caml_ba_data_val(src_buf),
      .size = Caml_ba_array_val(src_buf)->dim[0],
      .pos = 0};

  ZSTD_outBuffer output = {
      .dst = Caml_ba_data_val(dst_buf),
      .size = Caml_ba_array_val(dst_buf)->dim[0],
      .pos = 0};

  mlsize_t remaining = ZSTD_compressStream2(Zstd_cctx_val(context), &output, &input, Int_val(directive));

  if (ZSTD_isError(remaining))
  {
    caml_failwith(ZSTD_getErrorName(remaining));
  }

  tup = caml_alloc_tuple(3);

  Store_field(tup, 0, Val_int(remaining));
  Store_field(tup, 1, Val_int(input.pos));
  Store_field(tup, 2, Val_int(output.pos));

  CAMLreturn(tup);
}
