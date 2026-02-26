# Download ISTAT Data Split by Frequency

Downloads data for a dataset, automatically splitting by frequency if
multiple frequencies (A, Q, M) exist. Uses the availableconstraint
endpoint to detect available frequencies, then makes separate downloads
for each.

## Usage

``` r
download_istat_data_by_freq(
  dataset_id,
  filter = NULL,
  start_time = "",
  end_time = "",
  incremental = FALSE,
  timeout = NULL,
  verbose = TRUE,
  freq = NULL,
  check_update = FALSE,
  cache_dir = "meta"
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

- freq:

  Character string specifying a single frequency to download (A, Q, or
  M). If NULL (default), downloads all available frequencies. When
  specified, only the requested frequency is downloaded, avoiding
  unnecessary API calls.

- check_update:

  Logical indicating whether to check ISTAT's LAST_UPDATE timestamp
  before downloading. If TRUE and data hasn't changed since last
  download, returns NULL with a message. The check is performed once at
  the top level; internal calls to `download_istat_data` always use
  `check_update = FALSE`. Default is FALSE.

- cache_dir:

  Character string specifying directory for download log cache. Default
  is "meta".

## Value

Named list of data.tables by frequency (e.g., list(A = dt, Q = dt)).
Each element contains data for a single frequency. If the dataset has
only one frequency, returns a list with a single element. Returns NULL
if `check_update = TRUE` and data is unchanged since last download.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download with automatic frequency split
data_list <- download_istat_data_by_freq("151_914", start_time = "2020")

# Access by frequency
annual_data <- data_list$A
quarterly_data <- data_list$Q

# Download only a specific frequency (more efficient)
annual_only <- download_istat_data_by_freq("151_914", start_time = "2020", freq = "A")

# Single-frequency dataset
job_vacancies <- download_istat_data_by_freq("534_50", start_time = "2024")
monthly_data <- job_vacancies$M

# Check if data has been updated before downloading
data_list <- download_istat_data_by_freq("151_914", check_update = TRUE)
# Returns NULL with message if data unchanged since last download

# Use a custom cache directory
data_list <- download_istat_data_by_freq(
  "151_914",
  check_update = TRUE,
  cache_dir = "my_cache"
)
} # }
```
