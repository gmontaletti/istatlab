# Fetch data from ISTAT API in CSV format

**Deprecated**: This function is deprecated and will be removed in
version 1.0.0. Use
[`http_get()`](https://gmontaletti.github.io/istatlab/reference/http_get.md)
followed by
[`process_api_response()`](https://gmontaletti.github.io/istatlab/reference/process_api_response.md)
instead.

## Usage

``` r
istat_fetch_data_csv(url, timeout = 120, verbose = TRUE)
```

## Arguments

- url:

  Character string with the full API URL

- timeout:

  Numeric timeout in seconds

- verbose:

  Logical whether to print status messages

## Value

data.table with normalized column names or NULL on failure
