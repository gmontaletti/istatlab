# List Cached Demo.istat.it Data Files

Returns a summary table of all files present in the demo.istat.it cache
directory, including file size, modification time, and age.

## Usage

``` r
demo_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character string with the root cache directory. If `NULL` (default),
  the value from `get_istat_config()$demo$cache_dir` is used.

## Value

A `data.table` with columns:

- code:

  Dataset code extracted from the subdirectory name (uppercase).

- file:

  Filename.

- size_mb:

  File size in megabytes (rounded to 2 decimals).

- modified:

  File modification time as `POSIXct`.

- age_days:

  Number of days since the file was last modified (rounded to 1
  decimal).

If the cache directory does not exist or contains no files, an empty
`data.table` with the same columns is returned.

## Examples

``` r
if (FALSE) { # \dontrun{
# Show all cached demo files
status <- demo_cache_status()
print(status)

# Check a specific cache directory
status <- demo_cache_status(cache_dir = "my_cache")
} # }
```
