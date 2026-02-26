# HTTP POST with JSON Parsing

Sends a POST request through the throttled transport layer and parses
the response as JSON. Mirrors
[`http_get_json()`](https://gmontaletti.github.io/istatlab/reference/http_get_json.md)
for POST requests.

## Usage

``` r
http_post_json(
  url,
  body,
  timeout = 120,
  verbose = TRUE,
  simplifyVector = FALSE,
  flatten = FALSE,
  content_type = "application/x-www-form-urlencoded"
)
```

## Arguments

- url:

  Character string with the full URL

- body:

  Character string with the POST request body

- timeout:

  Numeric timeout in seconds

- verbose:

  Logical whether to log status messages

- simplifyVector:

  Logical passed to
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).
  Default FALSE.

- flatten:

  Logical passed to
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).
  Default FALSE.

- content_type:

  Character string with Content-Type header value. Defaults to
  `"application/x-www-form-urlencoded"`.

## Value

Parsed JSON object (list), or signals an error on failure
