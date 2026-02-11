# Compute Cache Path for a Demo Dataset File

Builds the full file path where a demo.istat.it download should be
cached. The layout is `{cache_dir}/{tolower(code)}/{filename}`. This
function does not create any directories on disk.

## Usage

``` r
get_demo_cache_path(code, filename, cache_dir = NULL)
```

## Arguments

- code:

  Character string identifying the dataset (e.g., `"D7B"`).

- filename:

  Character string with the file name (e.g., `"D7B2024.csv.zip"`).

- cache_dir:

  Character string with the root cache directory. If `NULL` (default),
  the value from `get_istat_config()$demo$cache_dir` is used.

## Value

Character string with the full cache file path.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- get_demo_cache_path("D7B", "D7B2024.csv.zip")
# "demo_data/d7b/D7B2024.csv.zip"
} # }
```
