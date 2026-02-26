# Download ISTAT Data for the Latest Edition

Downloads data for a dataset, filtering by the EDITION dimension. By
default, auto-detects the latest available edition and downloads only
that subset. This is useful for datasets that publish multiple editions
(revisions) of the same indicators, where typically only the most recent
edition is needed.

## Usage

``` r
download_istat_data_latest_edition(
  dataset_id,
  filter = NULL,
  start_time = "",
  end_time = "",
  edition = NULL,
  incremental = FALSE,
  timeout = NULL,
  verbose = TRUE,
  api = getOption("istatlab.default_api", "legacy")
)
```

## Arguments

- dataset_id:

  Character string specifying the ISTAT dataset ID (e.g., "534_50")

- filter:

  Character string specifying data filters. Default uses config value
  ("ALL")

- start_time:

  Character string specifying the start period (e.g., "2019"). If empty,
  downloads all available data

- end_time:

  Character string or Date specifying the end period (e.g., "2024",
  "2024-06", "2024-06-30"). If empty (default), no upper bound is
  applied. Accepts formats "YYYY", "YYYY-MM", or "YYYY-MM-DD".

- edition:

  Controls edition handling. If NULL (default), auto-detects and
  downloads only the latest edition. If "all", downloads all editions
  (no edition filter applied, equivalent to a regular download). If a
  specific edition code (e.g., "G_2024_01"), downloads only that
  edition.

- incremental:

  Logical or Date/character. If FALSE (default), fetches all data. If a
  Date object or character string ("YYYY", "YYYY-MM", or "YYYY-MM-DD"),
  fetches only data from that period onwards using the SDMX startPeriod
  parameter. Takes precedence over start_time if both are provided.

- timeout:

  Numeric timeout in seconds for the download operation. Default uses
  config value

- verbose:

  Logical indicating whether to print status messages. Default is TRUE

- api:

  Character string specifying the API surface to use. One of `"legacy"`
  (default), `"hvd_v1"`, or `"hvd_v2"`. Can be set session-wide via
  `options(istatlab.default_api = "hvd_v1")`.

## Value

A data.table containing the downloaded data with an additional 'id'
column, or NULL if the download fails. When the dataset has no EDITION
dimension, all data is returned without edition filtering.

## Examples

``` r
if (FALSE) { # \dontrun{
# Auto-detect and download only the latest edition
data <- download_istat_data_latest_edition("150_908", start_time = "2020")

# Download a specific edition
data <- download_istat_data_latest_edition(
  "150_908",
  edition = "G_2024_01",
  start_time = "2020"
)

# Download all editions (no edition filter)
data <- download_istat_data_latest_edition("150_908", edition = "all")
} # }
```
