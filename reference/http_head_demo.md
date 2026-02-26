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

Uses [`httr::HEAD()`](https://httr.r-lib.org/reference/HEAD.html) for
the HTTP request.
