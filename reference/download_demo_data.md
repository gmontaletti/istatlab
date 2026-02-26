# Download Demographic Data from Demo.istat.it

Downloads and extracts a single demographic dataset from ISTAT's
demo.istat.it portal. Files are cached locally as ZIP archives;
subsequent calls for the same parameters reuse the cached file unless
the remote has been updated or `force_download = TRUE` is set.

## Usage

``` r
download_demo_data(
  code,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL,
  subtype = NULL,
  cache_dir = NULL,
  force_download = FALSE,
  verbose = TRUE
)
```

## Arguments

- code:

  Character string identifying the dataset in the demo registry (e.g.,
  `"D7B"`, `"POS"`, `"TVM"`, `"PPR"`, `"RCS"`). Use
  [`list_demo_datasets`](https://gmontaletti.github.io/istatlab/reference/list_demo_datasets.md)
  to see available codes.

- year:

  Integer year for the data file. Required for patterns A, B, C, and E.

- territory:

  Character string specifying geographic territory (Pattern B only,
  e.g., `"Comuni"`, `"Province"`, `"Regioni"`).

- level:

  Character string specifying geographic aggregation level (Pattern C
  only, e.g., `"regionali"`, `"provinciali"`).

- type:

  Character string specifying data completeness type (Pattern C only,
  e.g., `"completi"`, `"sintetici"`).

- data_type:

  Character string specifying forecast data category (Pattern D only).

- geo_level:

  Character string specifying geographic resolution (Pattern D only,
  e.g., `"Regioni"`, `"Italia"`).

- subtype:

  Character string specifying the data subtype (Pattern E only, e.g.,
  `"nascita"`, `"cittadinanza"`).

- cache_dir:

  Character string specifying directory for cached files. If `NULL`
  (default), uses the value from `get_istat_config()$demo$cache_dir`.

- force_download:

  Logical indicating whether to bypass cache and re-download the file.
  Default `FALSE`.

- verbose:

  Logical indicating whether to print status messages. Default `TRUE`.

## Value

A `data.table` containing the extracted CSV data.

## Details

The function resolves the dataset code through the internal demo
registry, builds the download URL for the appropriate file-naming
pattern, and extracts the CSV content from the downloaded ZIP archive.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download monthly demographic balance for 2024
dt <- download_demo_data("D7B", year = 2024)

# Download population by territory
dt <- download_demo_data("POS", year = 2025, territory = "Comuni")

# Download mortality tables
dt <- download_demo_data("TVM", year = 2024, level = "regionali", type = "completi")

# Download population by citizenship (subtype)
dt <- download_demo_data("RCS", year = 2025, subtype = "cittadinanza")

# Download actuarial mortality tables (Pattern F, static file)
dt <- download_demo_data("TVA")

# Download deaths data (Pattern G, plain CSV)
dt <- download_demo_data("ISM", year = 2024)

# Force re-download
dt <- download_demo_data("D7B", year = 2024, force_download = TRUE)

# Interactive-only datasets will error with a portal link
# download_demo_data("MA1")  # Error: use interactive portal
} # }
```
