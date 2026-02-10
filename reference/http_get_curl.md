# HTTP GET using System Curl

Fallback function using system curl for downloads when httr has issues.
Uses temp file to capture response and returns content as string.

## Usage

``` r
http_get_curl(url, timeout, accept, verbose)
```

## Arguments

- url:

  Character string with the full URL

- timeout:

  Numeric timeout in seconds

- accept:

  Character string with Accept header value

- verbose:

  Logical whether to log status messages

## Value

A list with success, content, status_code, and error components
