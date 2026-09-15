#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/bigarray.h>
#include <caml/threads.h>

#include <string.h>
#include <zstd.h>

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

  cctx_val = caml_alloc_custom(&zstd_cctx_ops, sizeof(ZSTD_CCtx *), 0, 1);
  Zstd_cctx_val(cctx_val) = NULL;

  ZSTD_CCtx *cctx = ZSTD_createCCtx();

  if (cctx == NULL)
    caml_failwith("create_zstd_cctx_s have NULL");

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

  dctx_val = caml_alloc_custom(&zstd_dctx_ops, sizeof(ZSTD_DCtx *), 0, 1);
  Zstd_dctx_val(dctx_val) = NULL;

  ZSTD_DCtx *dctx = ZSTD_createDCtx();

  if (dctx == NULL)
    caml_failwith("create_zstd_dctx_s have NULL");

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
  CAMLparam1(src_size);
  CAMLreturn(Val_long(ZSTD_COMPRESSBOUND(Long_val(src_size))));
}

CAMLprim value caml_get_frame_string_content_size(value compressed_string)
{
  CAMLparam1(compressed_string);

  const size_t result =
      ZSTD_getFrameContentSize(String_val(compressed_string), caml_string_length(compressed_string));

  CAMLreturn(Val_long(result));
}

CAMLprim value caml_get_frame_bigstring_content_size(value compressed_bigstring)
{
  CAMLparam1(compressed_bigstring);

  const size_t result =
      ZSTD_getFrameContentSize(Caml_ba_data_val(compressed_bigstring), Caml_ba_array_val(compressed_bigstring)->dim[0]);

  CAMLreturn(Val_long(result));
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_compress_bigstring(value src_buf, value dst_buf, value level)
{
  CAMLparam3(src_buf, dst_buf, level);

  char *const uncompressed_data = Caml_ba_data_val(src_buf);
  const size_t uncompressed_data_length = Caml_ba_array_val(src_buf)->dim[0];

  char *const compressed_output_buffer = Caml_ba_data_val(dst_buf);
  const size_t compressed_output_buffer_length = Caml_ba_array_val(dst_buf)->dim[0];

  const size_t compression_level = Long_val(level);

  caml_enter_blocking_section();
  const size_t result = ZSTD_compress(compressed_output_buffer, compressed_output_buffer_length,
                                      uncompressed_data, uncompressed_data_length,
                                      compression_level);
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_compress_bigstring_with_context(value context, value src_buf, value dst_buf, value level)
{
  CAMLparam4(context, src_buf, dst_buf, level);

  char *const uncompressed_data = Caml_ba_data_val(src_buf);
  const size_t uncompressed_data_length = Caml_ba_array_val(src_buf)->dim[0];

  char *const compressed_output_buffer = Caml_ba_data_val(dst_buf);
  const size_t compressed_output_buffer_length = Caml_ba_array_val(dst_buf)->dim[0];

  const size_t compression_level = Int_val(level);

  ZSTD_CCtx *const compression_context = Zstd_cctx_val(context);

  caml_enter_blocking_section();
  const size_t result = ZSTD_compressCCtx(compression_context,
                                          compressed_output_buffer, compressed_output_buffer_length,
                                          uncompressed_data, uncompressed_data_length,
                                          compression_level);
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_compress_bigstring_with_context_and_dictionary(value context, value dictionary, value src_buf, value dst_buf, value level)
{
  CAMLparam5(context, dictionary, src_buf, dst_buf, level);

  char *const uncompressed_data = Caml_ba_data_val(src_buf);
  const size_t uncompressed_data_length = Caml_ba_array_val(src_buf)->dim[0];

  char *const compressed_output_buffer = Caml_ba_data_val(dst_buf);
  const size_t compressed_output_buffer_length = Caml_ba_array_val(dst_buf)->dim[0];

  char *const dictionary_string = Caml_ba_data_val(dictionary);
  const size_t dictionary_string_length = Caml_ba_array_val(dictionary)->dim[0];

  const size_t compression_level = Int_val(level);

  ZSTD_CCtx *const compression_context = Zstd_cctx_val(context);

  caml_enter_blocking_section();
  const size_t result = ZSTD_compress_usingDict(compression_context,
                                                compressed_output_buffer, compressed_output_buffer_length,
                                                uncompressed_data, uncompressed_data_length,
                                                dictionary_string, dictionary_string_length,
                                                compression_level);
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_long(result));
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_compress_string(value src_str, value dst_bytes, value level)
{
  CAMLparam3(src_str, dst_bytes, level);

  const size_t result = ZSTD_compress(
      Bytes_val(dst_bytes), caml_string_length(dst_bytes),
      String_val(src_str), caml_string_length(src_str),
      Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));

  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_compress_string_with_context(value context, value src_str, value dst_bytes, value level)
{
  CAMLparam4(context, src_str, dst_bytes, level);

  const size_t result = ZSTD_compressCCtx(
      Zstd_cctx_val(context),
      Bytes_val(dst_bytes), caml_string_length(dst_bytes),
      String_val(src_str), caml_string_length(src_str),
      Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_compress_string_with_context_and_dictionary(value context, value dictionary, value src_str, value dst_bytes, value level)
{
  CAMLparam5(context, dictionary, src_str, dst_bytes, level);

  const size_t result = ZSTD_compress_usingDict(
      Zstd_cctx_val(context),
      Bytes_val(dst_bytes), caml_string_length(dst_bytes),
      String_val(src_str), caml_string_length(src_str),
      Caml_ba_data_val(dictionary), Caml_ba_array_val(dictionary)->dim[0],
      Int_val(level));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// DECOMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_decompress_string(value src_str, value dst_bytes)
{
  CAMLparam2(src_str, dst_bytes);

  const size_t result = ZSTD_decompress(
      Bytes_val(dst_bytes), caml_string_length(dst_bytes),
      String_val(src_str), caml_string_length(src_str));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_decompress_string_with_context(value context, value src_str, value dst_bytes)
{
  CAMLparam3(context, src_str, dst_bytes);

  const size_t result = ZSTD_decompressDCtx(
      Zstd_dctx_val(context),
      Bytes_val(dst_bytes), caml_string_length(dst_bytes),
      String_val(src_str), caml_string_length(src_str));

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_decompress_string_with_context_and_dictionary(value context, value dictionary, value src_str, value dst_bytes)
{
  CAMLparam4(context, dictionary, src_str, dst_bytes);

  const size_t result = ZSTD_decompress_usingDict(
      Zstd_dctx_val(context),
      Bytes_val(dst_bytes), caml_string_length(dst_bytes),
      String_val(src_str), caml_string_length(src_str),
      Caml_ba_data_val(dictionary), Caml_ba_array_val(dictionary)->dim[0]);

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

////////////////////////////////////////////////////////////////////////

CAMLprim value caml_zstd_decompress_bigstring(value src_buf, value dst_buf)
{
  CAMLparam2(src_buf, dst_buf);

  char *const compressed_data = Caml_ba_data_val(src_buf);
  const size_t compressed_data_length = Caml_ba_array_val(src_buf)->dim[0];

  char *const uncompressed_output_buffer = Caml_ba_data_val(dst_buf);
  const size_t uncompressed_output_buffer_length = Caml_ba_array_val(dst_buf)->dim[0];

  caml_enter_blocking_section();
  const size_t result = ZSTD_decompress(uncompressed_output_buffer, uncompressed_output_buffer_length, compressed_data, compressed_data_length);
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_decompress_bigstring_with_context(value context, value src_buf, value dst_buf)
{
  CAMLparam3(context, src_buf, dst_buf);

  char *const compressed_data = Caml_ba_data_val(src_buf);
  const size_t compressed_data_length = Caml_ba_array_val(src_buf)->dim[0];

  char *const uncompressed_output_buffer = Caml_ba_data_val(dst_buf);
  const size_t uncompressed_output_buffer_length = Caml_ba_array_val(dst_buf)->dim[0];

  ZSTD_DCtx *const decompression_context = Zstd_dctx_val(context);

  caml_enter_blocking_section();
  const size_t result = ZSTD_decompressDCtx(decompression_context,
                                            uncompressed_output_buffer, uncompressed_output_buffer_length,
                                            compressed_data, compressed_data_length);
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

CAMLprim value caml_zstd_decompress_bigstring_with_context_and_dictionary(value context, value dictionary, value src_buf, value dst_buf)
{
  CAMLparam4(context, src_buf, dst_buf, dictionary);

  char *const compressed_data = Caml_ba_data_val(src_buf);
  const size_t compressed_data_length = Caml_ba_array_val(src_buf)->dim[0];

  char *const uncompressed_output_buffer = Caml_ba_data_val(dst_buf);
  const size_t uncompressed_output_buffer_length = Caml_ba_array_val(dst_buf)->dim[0];

  char *const dictionary_string = Caml_ba_data_val(dictionary);
  const size_t dictionary_string_length = Caml_ba_array_val(dictionary)->dim[0];

  ZSTD_DCtx *const decompression_context = Zstd_dctx_val(context);

  caml_enter_blocking_section();
  const size_t result = ZSTD_decompress_usingDict(decompression_context,
                                                  uncompressed_output_buffer, uncompressed_output_buffer_length,
                                                  compressed_data, compressed_data_length,
                                                  dictionary_string, dictionary_string_length);
  caml_leave_blocking_section();

  if (ZSTD_isError(result))
    caml_failwith(ZSTD_getErrorName(result));
  CAMLreturn(Val_long(result));
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// STREAM COMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

static void initialize_compression_result_tuple(value tup, size_t remaining, size_t input_position, size_t output_position)
{
  Store_field(tup, 0, Val_long(remaining));
  Store_field(tup, 1, Val_long(input_position));
  Store_field(tup, 2, Val_long(output_position));
}

CAMLprim value caml_zstd_compress_stream2(value context, value in_buffer, value out_buffer, value directive)
{
  CAMLparam4(context, in_buffer, out_buffer, directive);
  CAMLlocal1(tup);

  ZSTD_inBuffer input = {
      .src = Caml_ba_data_val(Field(in_buffer, 0)),
      .size = Long_val(Field(in_buffer, 2)),
      .pos = Long_val(Field(in_buffer, 1))};

  ZSTD_outBuffer output = {
      .dst = Caml_ba_data_val(Field(out_buffer, 0)),
      .size = Long_val(Field(out_buffer, 2)),
      .pos = Long_val(Field(out_buffer, 1))};

  size_t remaining = ZSTD_compressStream2(Zstd_cctx_val(context), &output, &input, Int_val(directive));

  if (ZSTD_isError(remaining))
  {
    caml_failwith(ZSTD_getErrorName(remaining));
  }

  tup = caml_alloc_tuple(3);
  initialize_compression_result_tuple(tup, remaining, input.pos, output.pos);

  CAMLreturn(tup);
}

CAMLprim value caml_zstd_compression_stream_in_size(value unit)
{
  return Val_long(ZSTD_CStreamInSize());
}

CAMLprim value caml_zstd_compression_stream_out_size(value unit)
{
  return Val_long(ZSTD_CStreamOutSize());
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// STREAM DECOMPRESS
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void custom_finalize_zstd_dstream_ops(value);

static struct custom_operations zstd_dstream_ops = {
    "zstd.DStream",
    custom_finalize_zstd_dstream_ops,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default};

#define Zstd_dstream_val(v) (*((ZSTD_DStream **)Data_custom_val(v)))

void custom_finalize_zstd_dstream_ops(value dstream)
{
  ZSTD_freeDStream(Zstd_dstream_val(dstream));
}

CAMLprim value caml_create_zstd_dstream(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(dstream_val);

  dstream_val = caml_alloc_custom(&zstd_dstream_ops, sizeof(ZSTD_DStream *), 0, 1);
  Zstd_dstream_val(dstream_val) = NULL;

  ZSTD_DStream *dstream = ZSTD_createDStream();

  if (dstream == NULL)
    caml_failwith("caml_create_zstd_dstream have NULL");

  Zstd_dstream_val(dstream_val) = dstream;

  CAMLreturn(dstream_val);
}

CAMLprim value caml_zstd_decompress_stream(value dstream, value in_buffer, value out_buffer)
{
  CAMLparam3(dstream, in_buffer, out_buffer);
  CAMLlocal1(tup);

  ZSTD_inBuffer input = {
      .src = Caml_ba_data_val(Field(in_buffer, 0)),
      .size = Long_val(Field(in_buffer, 2)),
      .pos = Long_val(Field(in_buffer, 1))};

  ZSTD_outBuffer output = {
      .dst = Caml_ba_data_val(Field(out_buffer, 0)),
      .size = Long_val(Field(out_buffer, 2)),
      .pos = Long_val(Field(out_buffer, 1))};

  size_t remaining = ZSTD_decompressStream(Zstd_dstream_val(dstream), &output, &input);

  if (ZSTD_isError(remaining))
  {
    caml_failwith(ZSTD_getErrorName(remaining));
  }

  tup = caml_alloc_tuple(3);
  initialize_compression_result_tuple(tup, remaining, input.pos, output.pos);

  CAMLreturn(tup);
}

CAMLprim value caml_zstd_decompression_stream_in_size(value unit)
{
  return Val_long(ZSTD_DStreamInSize());
}

CAMLprim value caml_zstd_decompression_stream_out_size(value unit)
{
  return Val_long(ZSTD_DStreamOutSize());
}