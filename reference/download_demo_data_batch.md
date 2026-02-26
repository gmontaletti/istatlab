# Download Multiple Demographic Datasets

Downloads several different demographic datasets for the same set of
parameters. Each dataset is downloaded independently; failures are
captured as warnings and the remaining successful results are still
returned.

## Usage

``` r
download_demo_data_batch(
  codes,
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

- codes:

  Character vector of dataset codes to download.

- year:

  Integer year for the data file (patterns A, B, C, E).

- territory:

  Character string specifying geographic territory (Pattern B only).

- level:

  Character string specifying geographic aggregation level (Pattern C
  only).

- type:

  Character string specifying data completeness type (Pattern C only).

- data_type:

  Character string specifying forecast data category (Pattern D only).

- geo_level:

  Character string specifying geographic resolution (Pattern D only).

- subtype:

  Character string specifying the data subtype (Pattern E only, e.g.,
  `"nascita"`, `"cittadinanza"`).

- cache_dir:

  Character string specifying directory for cached files. If `NULL`,
  uses the config default.

- force_download:

  Logical indicating whether to bypass cache. Default `FALSE`.

- verbose:

  Logical indicating whether to print status messages. Default `TRUE`.

## Value

A named list of `data.table` objects, one per dataset code. Names
correspond to the codes. Datasets that failed to download are excluded
from the list.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download multiple demographic balance datasets
results <- download_demo_data_batch(c("D7B", "P02", "P03"), year = 2024)
} # }
```
