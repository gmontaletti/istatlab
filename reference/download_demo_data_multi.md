# Download Demographic Data for Multiple Years

Downloads the same demographic dataset across multiple years and
combines the results into a single `data.table`. Each year is downloaded
independently; failures for individual years are captured as warnings
and the remaining successful results are still returned.

## Usage

``` r
download_demo_data_multi(
  code,
  years,
  territory = NULL,
  level = NULL,
  type = NULL,
  cache_dir = NULL,
  force_download = FALSE,
  verbose = TRUE
)
```

## Arguments

- code:

  Character string identifying the dataset in the demo registry (e.g.,
  `"D7B"`).

- years:

  Integer vector of years to download.

- territory:

  Character string specifying geographic territory (Pattern B only).

- level:

  Character string specifying geographic aggregation level (Pattern C
  only).

- type:

  Character string specifying data completeness type (Pattern C only).

- cache_dir:

  Character string specifying directory for cached files. If `NULL`,
  uses the config default.

- force_download:

  Logical indicating whether to bypass cache. Default `FALSE`.

- verbose:

  Logical indicating whether to print status messages. Default `TRUE`.

## Value

A `data.table` combining data from all successfully downloaded years. A
`year` column is added if not already present in the data. Returns an
empty `data.table` if all years fail.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download 3 years of demographic balance
dt <- download_demo_data_multi("D7B", years = 2022:2024)
} # }
```
