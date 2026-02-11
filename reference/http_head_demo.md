# HTTP HEAD Request for Demo Endpoint

Performs a lightweight HEAD request to retrieve response headers from
demo.istat.it URLs. Used primarily for update detection via the
`Last-Modified` header and file size estimation via `Content-Length`.

## Usage

``` r
http_head_demo(url, timeout = 10)
```

## Arguments

- url:

  Character string with the URL to check.

- timeout:

  Numeric timeout in seconds. Default 10.

## Value

A list with components:

- success:

  Logical indicating if HEAD request succeeded

- status_code:

  HTTP status code (integer), or NA on error

- last_modified:

  POSIXct parsed from Last-Modified header, or NA

- content_length:

  Integer parsed from Content-Length header, or NA

- error:

  Error message string, or NULL on success

## Details

Uses
[`curl::curl_fetch_memory()`](https://jeroen.r-universe.dev/curl/reference/curl_fetch.html)
with `nobody = TRUE` (same pattern as
[`check_endpoint_status()`](https://gmontaletti.github.io/istatlab/reference/check_endpoint_status.md)
in endpoints.R).
