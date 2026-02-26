# Build SDMX 3.0 Dimension Filter Parameters

Translates time period boundaries and dimension constraints into the
SDMX 3.0 query parameter syntax. Time periods are expressed as
`c[TIME_PERIOD]=ge:{start}+le:{end}` and arbitrary dimension filters as
`c[{DIM}]={value}`.

## Usage

``` r
build_sdmx3_filters(start_time = NULL, end_time = NULL, dim_filters = NULL)
```

## Arguments

- start_time:

  Character string specifying the start period (e.g., `"2020"`,
  `"2020-Q1"`, `"2020-01"`). Translated to a `ge:` (greater or equal)
  constraint on `TIME_PERIOD`. If `NULL`, no lower bound is applied.

- end_time:

  Character string specifying the end period. Translated to a `le:`
  (less or equal) constraint on `TIME_PERIOD`. If `NULL`, no upper bound
  is applied.

- dim_filters:

  Named list where names are SDMX dimension identifiers and values are
  the corresponding filter expressions. For example,
  `list(FREQ = "M", REF_AREA = "IT")` produces `c[FREQ]=M` and
  `c[REF_AREA]=IT`. Can be `NULL` for no dimension filtering.

## Value

Character vector of query parameter strings suitable for appending to a
URL query string. Returns a zero-length character vector when no filters
are specified.

## Examples

``` r
if (FALSE) { # \dontrun{
# Time range only
build_sdmx3_filters(start_time = "2020", end_time = "2025")
# "c[TIME_PERIOD]=ge:2020+le:2025"

# Open-ended time range (no end)
build_sdmx3_filters(start_time = "2020")
# "c[TIME_PERIOD]=ge:2020"

# Dimension filters only
build_sdmx3_filters(dim_filters = list(FREQ = "M", REF_AREA = "IT"))
# c("c[FREQ]=M", "c[REF_AREA]=IT")

# Combined time and dimension filters
build_sdmx3_filters(start_time = "2020", end_time = "2025",
                    dim_filters = list(FREQ = "M"))
# c("c[TIME_PERIOD]=ge:2020+le:2025", "c[FREQ]=M")

# No filters
build_sdmx3_filters()
# character(0)
} # }
```
