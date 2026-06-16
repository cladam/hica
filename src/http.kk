/*
 * hica – HTTP client (libcurl wrapper)
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module http

extern import
  c file "curl-inline.c"

// Fetch a URL and return the response body as a string.
// Returns an empty string on any error (network, timeout, etc.).
pub extern http-get( url : string ) : io string
  c "kk_hica_http_get"

// Download a URL and write the response body to dest-path.
// Returns 0 on success, non-zero on error.
pub extern http-download( url : string, dest-path : string ) : io int
  c "kk_hica_http_download"
