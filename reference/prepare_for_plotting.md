# Prepare ISTAT Data for Plotting

Downloads or processes ISTAT data, applies labels, extracts
non-invariant columns, computes extended statistics per time series, and
saves outputs for visualization.

## Usage

``` r
prepare_for_plotting(
  data,
  output_dir = "output",
  prefix = NULL,
  start_time = "",
  freq = NULL,
  save_data = TRUE,
  save_report = TRUE,
  verbose = TRUE
)
```

## Arguments

- data:

  Either a character string (dataset_id to download) or a data.table
  containing raw ISTAT data with ObsDimension and ObsValue columns.

- output_dir:

  Character string specifying the output directory for saved files.
  Default is "output".

- prefix:

  Character string to prepend to output filenames. Default is NULL (uses
  dataset_id or "data").

- start_time:

  Character string specifying start period for download. Only used when
  data is a dataset_id. Default is "".

- freq:

  Character string specifying frequency filter (A, Q, M). Only used when
  data is a dataset_id. Default is NULL (all frequencies).

- save_data:

  Logical indicating whether to save data.rds. Default is TRUE.

- save_report:

  Logical indicating whether to save report files. Default is TRUE.

- verbose:

  Logical indicating whether to print status messages. Default is TRUE.

## Value

A list with class "istat_plot_ready" containing:

- data: data.table with labeled data ready for ggplot2

- report: list with structured metadata and series_stats (data.table
  with labels)

- files: list with paths to saved files (data_rds, report_rds)

- summary: Quick summary of the data (n_rows, n_series, date_range)

## Examples

``` r
if (FALSE) { # \dontrun{
# From dataset_id (downloads and processes)
result <- prepare_for_plotting("534_50", output_dir = "output")

# From pre-downloaded data
raw_data <- download_istat_data("534_50")
result <- prepare_for_plotting(raw_data, prefix = "job_vacancies")

# Access components
plot_data <- result$data
stats <- result$report$series_stats
} # }
```
