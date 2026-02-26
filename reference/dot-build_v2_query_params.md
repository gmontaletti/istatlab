# Build HVD v2 Query Parameter Strings

Assembles query string parameters for HVD v2 GET data requests.
Delegates dimension and time period filter construction to
[`build_sdmx3_filters()`](https://gmontaletti.github.io/istatlab/reference/build_sdmx3_filters.md).

## Usage

``` r
.build_v2_query_params(
  start_time = NULL,
  end_time = NULL,
  dim_filters = NULL,
  updated_after = NULL,
  lastNObservations = NULL
)
```

## Arguments

- start_time:

  Character start period.

- end_time:

  Character end period.

- dim_filters:

  Named list of dimension filters.

- updated_after:

  Character ISO 8601 timestamp.

- lastNObservations:

  Integer observation limit.

## Value

Character vector of query parameter strings (URL-encoded where needed).
