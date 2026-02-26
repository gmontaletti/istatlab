# HTTP POST using httr Package

Internal function that performs HTTP POST using the httr package.
Mirrors
[`http_get_httr()`](https://gmontaletti.github.io/istatlab/reference/http_get_httr.md)
but sends a POST request with a body payload. Designed for SDMX filter
key queries that exceed GET URL length limits.

## Usage

``` r
http_post_httr(url, body, timeout, accept, content_type, verbose)
```

## Arguments

- url:

  Character string with the full URL

- body:

  Character string with the POST request body

- timeout:

  Numeric timeout in seconds

- accept:

  Character string with Accept header value

- content_type:

  Character string with Content-Type header value

- verbose:

  Logical whether to log status messages

## Value

A list with success, content, status_code, error, and headers components
