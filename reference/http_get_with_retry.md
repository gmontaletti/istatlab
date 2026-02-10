# HTTP GET with Retry and Rate Limiting

Wraps http_get() with throttling, retry logic, and ban detection.
Handles 429 (Too Many Requests) and 503 (Service Unavailable) with
exponential backoff.

## Usage

``` r
http_get_with_retry(url, timeout = 120, accept = NULL, verbose = TRUE)
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

A list with same structure as http_get()
