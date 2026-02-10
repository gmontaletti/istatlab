# Build ISTAT API URL

Constructs API URLs for different ISTAT SDMX endpoints using centralized
configuration.

## Usage

``` r
build_istat_url(
  endpoint,
  dataset_id = NULL,
  filter = "ALL",
  start_time = NULL,
  end_time = NULL,
  dsd_ref = NULL,
  updated_after = NULL,
  lastNObservations = NULL
)
```

## Arguments

- endpoint:

  Character string specifying the endpoint type ("data", "dataflow",
  "datastructure", "codelist", "availableconstraint")

- dataset_id:

  Character string specifying dataset ID (required for data endpoint)

- filter:

  Character string specifying data filters (for data endpoint)

- start_time:

  Character string specifying start period (for data endpoint)

- end_time:

  Character string specifying end period (for data endpoint)

- dsd_ref:

  Character string specifying data structure reference (for
  datastructure)

- updated_after:

  POSIXct timestamp. If provided, the URL will include the updatedAfter
  parameter to retrieve only data changed since this time. Used for
  incremental update detection.

- lastNObservations:

  Integer. If provided, limits the response to the last N observations
  per time series. Useful for reducing data transfer in connectivity
  checks.

## Value

Character string containing the constructed API URL

## Examples

``` r
if (FALSE) { # \dontrun{
# Build data URL
url <- build_istat_url("data", dataset_id = "534_50", start_time = "2020")

# Build dataflow URL
url <- build_istat_url("dataflow")

# Build datastructure URL
url <- build_istat_url("datastructure", dsd_ref = "DSD_534_50")

# Build data URL with update detection
timestamp <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
url <- build_istat_url("data", dataset_id = "534_50", updated_after = timestamp)

# Build lightweight URL for connectivity check
url <- build_istat_url("data", dataset_id = "534_50", lastNObservations = 1)
} # }
```
