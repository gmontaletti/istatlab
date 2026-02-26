# HTTP POST Request

Performs HTTP POST request using httr. Mirrors
[`http_get()`](https://gmontaletti.github.io/istatlab/reference/http_get.md)
but for POST requests with a body payload. No curl fallback is provided
for POST.

## Usage

``` r
http_post(
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

  Character string with the POST request body (typically an SDMX filter
  key for large queries)

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

A list with components:

- success: Logical indicating if request succeeded

- content: Character string with response body (or NULL)

- status_code: HTTP status code (or NA)

- error: Error message if failed (or NULL)

- method: Character `"httr"` (POST uses httr only)

- headers: Response headers list (when available)
