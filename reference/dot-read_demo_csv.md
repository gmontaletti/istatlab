# Read a Single CSV File with Encoding Fallback

Helper that reads a CSV file using
[`data.table::fread()`](https://rdrr.io/pkg/data.table/man/fread.html),
trying UTF-8 first and falling back to Latin-1 on encoding errors.

## Usage

``` r
.read_demo_csv(csv_path, csv_name, verbose)
```

## Arguments

- csv_path:

  Character string with the full path to the CSV file.

- csv_name:

  Character string with the original filename (for logging).

- verbose:

  Logical whether to log status messages.

## Value

A `data.table`.
