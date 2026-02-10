# Make HTTP GET request to ISTAT API

**Deprecated**: This function is deprecated and will be removed in
version 1.0.0. Use
[`http_get()`](https://gmontaletti.github.io/istatlab/reference/http_get.md)
from http_transport.R instead.

## Usage

``` r
istat_http_get(url, timeout = 120, accept = NULL, verbose = TRUE)
```

## Arguments

- url:

  Character string with the full API URL

- timeout:

  Numeric timeout in seconds

- accept:

  Character string with Accept header value

- verbose:

  Logical whether to print status messages

## Value

httr response object or NULL on failure
