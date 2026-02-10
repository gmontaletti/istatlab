# HTTP GET with JSON Parsing

Fetches a URL through the throttled transport layer and parses the
response as JSON. Replaces direct httr::GET + jsonlite::fromJSON calls.

## Usage

``` r
http_get_json(
  url,
  timeout = 120,
  verbose = TRUE,
  simplifyVector = FALSE,
  flatten = FALSE
)
```

## Arguments

- url:

  Character string with the full URL

- timeout:

  Numeric timeout in seconds

- verbose:

  Logical whether to log status messages

- simplifyVector:

  Logical passed to jsonlite::fromJSON. Default FALSE.

- flatten:

  Logical passed to jsonlite::fromJSON. Default FALSE.

## Value

Parsed JSON object (list), or signals an error on failure
