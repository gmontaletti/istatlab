# Retrieve Available Values for a Dimension

Queries the HVD availability endpoint to discover valid values for one
or all dimensions of a dataset. This is useful for building filter keys
before downloading data.

## Usage

``` r
hvd_get_available_values(
  dataset_id,
  dimension = "all",
  api_version = "hvd_v1",
  timeout = 120,
  verbose = TRUE
)
```

## Arguments

- dataset_id:

  Character string specifying the dataset identifier.

- dimension:

  Character string specifying the dimension to query, or `"all"`
  (default) to retrieve values for every dimension.

- api_version:

  Character string indicating the API surface to use. One of `"hvd_v1"`
  (default) or `"hvd_v2"`.

- timeout:

  Numeric timeout in seconds for the HTTP request. Default 120.

- verbose:

  Logical controlling structured logging output. Default TRUE.

## Value

A parsed JSON list representing the available values, or `NULL` if the
request fails.
