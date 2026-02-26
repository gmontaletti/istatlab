# Download Data from ISTAT HVD API

Downloads statistical data from the ISTAT High-Value Datasets (HVD) API.
Provides direct access to HVD endpoints for users who want explicit
control over the API version and request method. Supports both SDMX 2.1
(v1) and SDMX 3.0 (v2) interfaces.

## Usage

``` r
download_hvd_data(
  dataset_id,
  version = "v1",
  filter = "ALL",
  start_time = "",
  end_time = "",
  method = "GET",
  timeout = NULL,
  verbose = TRUE,
  ...
)
```

## Arguments

- dataset_id:

  Character string specifying the ISTAT dataset ID (e.g., `"534_50"`)

- version:

  Character string: `"v1"` (default, SDMX 2.1) or `"v2"` (SDMX 3.0,
  experimental)

- filter:

  Character string specifying data filters. Default `"ALL"` retrieves
  all available data.

- start_time:

  Character string specifying the start period (e.g., `"2019"`,
  `"2020-Q1"`, `"2020-01"`)

- end_time:

  Character string specifying the end period

- method:

  Character string: `"GET"` (default) or `"POST"`. Use POST for complex
  filter keys that may exceed URL length limits.

- timeout:

  Numeric timeout in seconds. Default uses the centralized configuration
  value.

- verbose:

  Logical whether to print status messages. Default `TRUE`.

- ...:

  Additional arguments passed to version-specific handlers (e.g.,
  `updated_after`, `lastNObservations`, `detail`, `context`,
  `agency_id`)

## Value

A data.table with the downloaded data and an additional `id` column
containing the dataset identifier, or `NULL` if the download fails.

## Details

The HVD API is the newer ISTAT data delivery platform. Version v1 (SDMX
2.1) is the stable interface; v2 (SDMX 3.0) is experimental. Both
versions return data normalized to the same column naming convention for
compatibility with the rest of istatlab.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download via HVD v1 (default, stable)
dt <- download_hvd_data("534_50", start_time = "2020")

# Download via HVD v2 (experimental)
dt <- download_hvd_data("534_50", version = "v2", start_time = "2020")

# Use POST method for complex filters
dt <- download_hvd_data(
  "150_908",
  filter = "M..........",
  method = "POST",
  start_time = "2023"
)

# Limit to last 5 observations per series
dt <- download_hvd_data("534_50", lastNObservations = 5)
} # }
```
