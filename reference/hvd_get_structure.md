# Retrieve HVD Data Structure Definition

Fetches the data structure definition (DSD) for a dataset from the ISTAT
Historical Data Vault. The DSD describes dimensions, attributes, and
measures that compose the dataset.

## Usage

``` r
hvd_get_structure(
  dataset_id,
  api_version = "hvd_v1",
  timeout = 120,
  verbose = TRUE
)
```

## Arguments

- dataset_id:

  Character string specifying the dataset identifier (e.g., `"22_289"`).

- api_version:

  Character string indicating the API surface to use. One of `"hvd_v1"`
  (default) or `"hvd_v2"`.

- timeout:

  Numeric timeout in seconds for the HTTP request. Default 120.

- verbose:

  Logical controlling structured logging output. Default TRUE.

## Value

A parsed JSON list representing the data structure definition, or `NULL`
if the request fails.
