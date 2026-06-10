# Refresh Expired Codelists

Downloads fresh versions of expired codelists and updates cache. Only
refreshes codelists that have exceeded their staggered TTL.

## Usage

``` r
refresh_expired_codelists(
  cache_dir = .istatlab_cache_dir(),
  force_refresh = FALSE,
  verbose = TRUE
)
```

## Arguments

- cache_dir:

  Character, cache directory path. Defaults to the `ISTATLAB_CACHE_DIR`
  environment variable, or `"meta"` if unset.

- force_refresh:

  Logical, refresh all codelists regardless of TTL. Default FALSE

- verbose:

  Logical, print status messages. Default TRUE

## Value

Invisible list with refresh statistics:

- refreshed: Number of codelists successfully refreshed

- total: Total number of cached codelists

- expired: Character vector of expired codelist IDs

## Examples

``` r
if (FALSE) { # \dontrun{
# Refresh only expired codelists
result <- refresh_expired_codelists()
message("Refreshed ", result$refreshed, " codelists")

# Force refresh all
refresh_expired_codelists(force_refresh = TRUE)
} # }
```
