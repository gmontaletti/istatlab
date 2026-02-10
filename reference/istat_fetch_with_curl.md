# Fetch data using system curl command

**Deprecated**: This function is deprecated and will be removed in
version 1.0.0. Use
[`http_get_curl()`](https://gmontaletti.github.io/istatlab/reference/http_get_curl.md)
from http_transport.R instead.

## Usage

``` r
istat_fetch_with_curl(url, timeout = 120, accept, verbose = TRUE)
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

Character string with CSV content or NULL on failure
