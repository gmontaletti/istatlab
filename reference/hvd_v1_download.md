# Download Data via HVD v1 API (SDMX 2.1)

Retrieves data from the ISTAT HVD SDMX 2.1 endpoint. Supports both GET
requests (filter in URL path) and POST requests (filter in request
body).

## Usage

``` r
hvd_v1_download(
  dataset_id,
  filter = "ALL",
  start_time = "",
  end_time = "",
  timeout = 240,
  verbose = TRUE,
  method = "GET",
  updated_after = NULL,
  lastNObservations = NULL,
  detail = NULL,
  includeHistory = NULL
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

- updated_after:

  Character string in ISO 8601 format for incremental retrieval. If
  provided, only data updated after this timestamp is returned.

- lastNObservations:

  Integer limiting response to the last N observations per time series

- detail:

  Character string controlling response detail level (e.g., `"full"`,
  `"dataonly"`, `"nodata"`)

- includeHistory:

  Logical whether to include revision history

## Value

An `istat_result` object
