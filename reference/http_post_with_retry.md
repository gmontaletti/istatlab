# HTTP POST with Retry and Rate Limiting

Wraps
[`http_post()`](https://gmontaletti.github.io/istatlab/reference/http_post.md)
with throttling, retry logic, and ban detection. Handles 429 (Too Many
Requests) and 503 (Service Unavailable) with exponential backoff.
Mirrors
[`http_get_with_retry()`](https://gmontaletti.github.io/istatlab/reference/http_get_with_retry.md)
for POST requests.

## Usage

``` r
http_post_with_retry(
  url,
  body,
  timeout = 120,
  accept = NULL,
  content_type = "application/x-www-form-urlencoded",
  verbose = TRUE
)
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

  Character string with Content-Type header value. Defaults to
  `"application/x-www-form-urlencoded"`.

- verbose:

  Logical whether to log status messages

## Value

A list with same structure as
[`http_post()`](https://gmontaletti.github.io/istatlab/reference/http_post.md)
