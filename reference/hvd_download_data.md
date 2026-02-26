# Download Data via HVD API

Internal dispatcher that routes HVD download requests to the appropriate
version-specific handler. Called by existing download functions when the
api surface is not `"legacy"`.

## Usage

``` r
hvd_download_data(
  dataset_id,
  api_version,
  filter = "ALL",
  start_time = "",
  end_time = "",
  timeout = NULL,
  verbose = TRUE,
  method = "GET",
  ...
)
```

## Arguments

- dataset_id:

  Character string specifying the ISTAT dataset ID

- api_version:

  Character string: `"hvd_v1"` (SDMX 2.1) or `"hvd_v2"` (SDMX 3.0)

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

- ...:

  Additional arguments passed to version-specific handlers

## Value

An `istat_result` object (same structure as
[`process_api_response()`](https://gmontaletti.github.io/istatlab/reference/process_api_response.md))
