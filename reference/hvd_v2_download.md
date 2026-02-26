# Download Data via HVD v2 API (SDMX 3.0)

Retrieves data from the ISTAT HVD SDMX 3.0 endpoint. Supports both GET
requests (filter in URL path) and POST requests (filter in request
body). Applies v2-specific column normalization to ensure consistent
output regardless of API version.

## Usage

``` r
hvd_v2_download(
  dataset_id,
  filter = "ALL",
  start_time = "",
  end_time = "",
  timeout = 240,
  verbose = TRUE,
  method = "GET",
  context = NULL,
  agency_id = NULL,
  version = NULL,
  dim_filters = NULL,
  updated_after = NULL,
  lastNObservations = NULL
)
```

## Arguments

- dataset_id:

  Character string specifying the ISTAT dataset ID

- filter:

  Character string specifying data filters (default `"ALL"`)

- start_time:

  Character string specifying the start period

- end_time:

  Character string specifying the end period

- timeout:

  Numeric timeout in seconds

- verbose:

  Logical whether to log status messages

- method:

  Character string: `"GET"` (default) or `"POST"`

- context:

  Character string specifying the SDMX 3.0 context

- agency_id:

  Character string specifying the data provider agency

- version:

  Character string specifying the dataflow version

- dim_filters:

  Named list of dimension filters for v2 URL construction

- updated_after:

  Character string in ISO 8601 format for incremental retrieval

- lastNObservations:

  Integer limiting response to the last N observations per time series

## Value

An `istat_result` object
