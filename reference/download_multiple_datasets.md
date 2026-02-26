# Download Multiple Datasets

Downloads multiple datasets from ISTAT SDMX API in parallel. Uses
centralized configuration for default values.

## Usage

``` r
download_multiple_datasets(
  dataset_ids,
  filter = NULL,
  start_time = "",
  incremental = FALSE,
  n_cores = parallel::detectCores() - 1,
  verbose = TRUE,
  updated_after = NULL,
  api = getOption("istatlab.default_api", "legacy")
)
```

## Arguments

- dataset_ids:

  Character vector of ISTAT dataset IDs

- filter:

  Character string specifying data filters. Default uses config value
  ("ALL")

- start_time:

  Character string specifying the start period

- incremental:

  Logical or Date/character. If FALSE (default), fetches all data. If a
  Date object or character string ("YYYY", "YYYY-MM", or "YYYY-MM-DD"),
  fetches only data from that period onwards. Takes precedence over
  start_time.

- n_cores:

  Integer number of cores to use for parallel processing. Default is
  parallel::detectCores() - 1

- verbose:

  Logical indicating whether to print status messages. Default is TRUE

- updated_after:

  POSIXct timestamp. If provided, only data updated since this time will
  be retrieved for all datasets. Used for incremental update detection.

- api:

  Character string specifying the API surface to use. One of `"legacy"`
  (default), `"hvd_v1"`, or `"hvd_v2"`. Can be set session-wide via
  `options(istatlab.default_api = "hvd_v1")`.

## Value

A named list of data.tables, one for each dataset

## Examples

``` r
if (FALSE) { # \dontrun{
# Download multiple datasets
datasets <- c("534_50", "534_51", "534_52")
data_list <- download_multiple_datasets(datasets, start_time = "2020")

# Access individual datasets
vacancies_50 <- data_list[["534_50"]]

# Download only updated data
timestamp <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
updated_list <- download_multiple_datasets(datasets, updated_after = timestamp)
} # }
```
