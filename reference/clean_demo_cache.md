# Remove Cached Demo.istat.it Data Files

Deletes files from the demo.istat.it cache directory. Filtering by
dataset code and/or maximum file age is supported. When both `code` and
`max_age_days` are `NULL`, all cached files are removed.

## Usage

``` r
clean_demo_cache(code = NULL, cache_dir = NULL, max_age_days = NULL)
```

## Arguments

- code:

  Character string with the dataset code to clean (e.g., `"D7B"`). If
  `NULL` (default), files for all datasets are considered.

- cache_dir:

  Character string with the root cache directory. If `NULL` (default),
  the value from `get_istat_config()$demo$cache_dir` is used.

- max_age_days:

  Numeric maximum file age in days. Only files whose modification time
  is older than this threshold are removed. If `NULL` (default), no age
  filtering is applied.

## Value

Invisible integer count of files removed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Remove all cached files for dataset D7B
clean_demo_cache(code = "D7B")

# Remove files older than 60 days
clean_demo_cache(max_age_days = 60)

# Remove all cached demo files
clean_demo_cache()
} # }
```
