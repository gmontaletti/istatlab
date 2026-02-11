# Parse Raw HTTP Response Headers

Splits raw header text into a named list with lowercase keys. Handles
multi-line values and CRLF line endings.

## Usage

``` r
.parse_response_headers(raw_headers)
```

## Arguments

- raw_headers:

  Character string of raw HTTP headers.

## Value

Named list of header values (keys are lowercase).
