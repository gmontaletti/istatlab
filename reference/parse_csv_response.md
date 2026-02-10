# Parse CSV Response

Parses CSV text response into a data.table using data.table::fread for
high performance.

## Usage

``` r
parse_csv_response(csv_text, verbose = TRUE)
```

## Arguments

- csv_text:

  Character string containing CSV data

- verbose:

  Logical whether to log status

## Value

data.table or NULL on parse failure
