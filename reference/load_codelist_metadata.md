# Load Codelist Metadata Cache

Loads per-codelist metadata (timestamps, TTL) from cache. Returns empty
list if cache doesn't exist or is corrupted.

## Usage

``` r
load_codelist_metadata(cache_dir = "meta")
```

## Arguments

- cache_dir:

  Character, cache directory path. Default "meta"

## Value

Named list of codelist metadata, where each element contains:

- first_download: POSIXct timestamp of first download

- last_refresh: POSIXct timestamp of last refresh

- ttl_days: Numeric TTL in days for this codelist

## Examples

``` r
if (FALSE) { # \dontrun{
# Load codelist metadata
cl_meta <- load_codelist_metadata()
# Access metadata for specific codelist
cl_meta[["CL_FREQ"]]$ttl_days
} # }
```
