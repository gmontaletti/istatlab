# Build HVD v1 Query Parameter Strings

Assembles the query string parameters for HVD v1 GET data requests. Only
non-NULL parameters are included in the output.

## Usage

``` r
.build_v1_query_params(
  start_time = NULL,
  end_time = NULL,
  updated_after = NULL,
  lastNObservations = NULL,
  detail = NULL,
  includeHistory = NULL
)
```

## Arguments

- start_time:

  Character start period.

- end_time:

  Character end period.

- updated_after:

  Character ISO 8601 timestamp.

- lastNObservations:

  Integer observation limit.

- detail:

  Character detail level.

- includeHistory:

  Logical include-history flag.

## Value

Character vector of `name=value` query parameter strings.
