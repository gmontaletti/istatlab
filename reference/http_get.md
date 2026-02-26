# HTTP GET Request

Performs HTTP GET request using httr. This is the single point for all
HTTP operations.

## Usage

``` r
http_get(url, timeout = 120, accept = NULL, verbose = TRUE)
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

A list with components:

- success: Logical indicating if request succeeded

- content: Character string with response body (or NULL)

- status_code: HTTP status code (or NA)

- error: Error message if failed (or NULL)

- method: Character `"httr"`

- headers: Response headers list (when available)
