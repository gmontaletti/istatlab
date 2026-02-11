# Extract CSV Data from a Demo ZIP Archive

Extracts CSV files from a ZIP archive downloaded from demo.istat.it and
returns the contents as a `data.table`. When the archive contains
multiple CSV files they are combined with
[`data.table::rbindlist()`](https://rdrr.io/pkg/data.table/man/rbindlist.html).

## Usage

``` r
extract_demo_csv(zip_path, verbose = TRUE)
```

## Arguments

- zip_path:

  Character string with the path to the ZIP file.

- verbose:

  Logical whether to log status messages. Default `TRUE`.

## Value

A `data.table` with the contents of the CSV file(s).

## Details

Encoding is attempted first as UTF-8; if that fails (common with older
ISTAT files), Latin-1 is used as fallback.

## Examples

``` r
if (FALSE) { # \dontrun{
dt <- extract_demo_csv("demo_data/d7b/D7B2024.csv.zip")
str(dt)
} # }
```
