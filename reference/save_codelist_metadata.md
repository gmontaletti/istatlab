# Save Codelist Metadata Cache

Saves per-codelist metadata (timestamps, TTL) to cache.

## Usage

``` r
save_codelist_metadata(metadata, cache_dir = "meta")
```

## Arguments

- metadata:

  Named list of codelist metadata to save

- cache_dir:

  Character, cache directory path. Default "meta"

## Value

Invisible NULL

## Examples

``` r
if (FALSE) { # \dontrun{
# Update and save metadata
cl_meta <- load_codelist_metadata()
cl_meta[["CL_FREQ"]] <- list(
  first_download = Sys.time(),
  last_refresh = Sys.time(),
  ttl_days = compute_codelist_ttl("CL_FREQ")
)
save_codelist_metadata(cl_meta)
} # }
```
