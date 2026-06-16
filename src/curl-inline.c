/*
 * hica – libcurl HTTP client trampoline
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Provides two functions:
 *   kk_hica_http_get(url)        -> body as kk_string_t, or empty string on error
 *   kk_hica_http_download(url, dest_path) -> 0 on success, non-zero on error
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

/* ---------------------------------------------------------------------------
 * Internal: growing buffer for response body
 * ------------------------------------------------------------------------- */

typedef struct {
  char*  data;
  size_t size;
} hica_buf_t;

static size_t hica_write_buf(void* ptr, size_t size, size_t nmemb, void* userdata) {
  hica_buf_t* buf = (hica_buf_t*)userdata;
  size_t bytes = size * nmemb;
  char* newdata = realloc(buf->data, buf->size + bytes + 1);
  if (!newdata) return 0;
  buf->data = newdata;
  memcpy(buf->data + buf->size, ptr, bytes);
  buf->size += bytes;
  buf->data[buf->size] = '\0';
  return bytes;
}

static size_t hica_write_file(void* ptr, size_t size, size_t nmemb, void* userdata) {
  return fwrite(ptr, size, nmemb, (FILE*)userdata);
}

/* ---------------------------------------------------------------------------
 * kk_hica_http_get: fetch URL, return body as kk_string_t
 * Returns empty string on any error.
 * ------------------------------------------------------------------------- */

static kk_string_t kk_hica_http_get(kk_string_t url_str, kk_context_t* ctx) {
  const char* url = kk_string_cbuf_borrow(url_str, NULL, ctx);

  hica_buf_t buf = { NULL, 0 };
  int ok = 0;

  CURL* curl = curl_easy_init();
  if (curl) {
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, hica_write_buf);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buf);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    CURLcode res = curl_easy_perform(curl);
    if (res == CURLE_OK) ok = 1;
    curl_easy_cleanup(curl);
  }

  kk_string_drop(url_str, ctx);

  if (!ok || !buf.data) {
    free(buf.data);
    return kk_string_empty();
  }

  /* curl used stdlib realloc; copy into kk_malloc so Koka can free it safely */
  char* kk_buf = (char*)kk_malloc(buf.size + 1, ctx);
  memcpy(kk_buf, buf.data, buf.size + 1);
  free(buf.data);

  kk_string_t result = kk_string_alloc_raw_len(buf.size, kk_buf, true /* owns */, ctx);
  return result;
}

/* ---------------------------------------------------------------------------
 * kk_hica_http_download: fetch URL, write to dest path
 * Returns 0 on success, 1 on error.
 * ------------------------------------------------------------------------- */

static kk_integer_t kk_hica_http_download(kk_string_t url_str, kk_string_t dest_str, kk_context_t* ctx) {
  const char* url  = kk_string_cbuf_borrow(url_str,  NULL, ctx);
  const char* dest = kk_string_cbuf_borrow(dest_str, NULL, ctx);

  FILE* fp = fopen(dest, "wb");
  if (!fp) {
    kk_string_drop(url_str,  ctx);
    kk_string_drop(dest_str, ctx);
    return kk_integer_from_int(1, ctx);
  }

  int ok = 0;
  CURL* curl = curl_easy_init();
  if (curl) {
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, hica_write_file);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 60L);
    CURLcode res = curl_easy_perform(curl);
    if (res == CURLE_OK) ok = 1;
    curl_easy_cleanup(curl);
  }
  fclose(fp);

  kk_string_drop(url_str,  ctx);
  kk_string_drop(dest_str, ctx);
  return kk_integer_from_int(ok ? 0 : 1, ctx);
}
