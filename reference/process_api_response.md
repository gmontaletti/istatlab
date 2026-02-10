# Process API Response

Main function to process raw API response into final data.table.
Combines parsing, normalization, and checksum computation.

## Usage

``` r
process_api_response(http_result, verbose = TRUE)
```

## Arguments

- http_result:

  Result from http_get() function

- verbose:

  Logical whether to log status

## Value

istat_result object with processed data
