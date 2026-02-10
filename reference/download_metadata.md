# Download Dataset Metadata

Downloads metadata for ISTAT datasets including dataflows, codelists,
and dimensions.

## Usage

``` r
download_metadata(force_update = FALSE, cache_dir = "meta")
```

## Arguments

- force_update:

  Logical indicating whether to force update of cached metadata. Default
  is FALSE, which uses cached data if available and less than 14 days
  old

- cache_dir:

  Character string specifying the directory for caching metadata.
  Default is "meta"

## Value

A list containing dataflows metadata

## Examples

``` r
if (FALSE) { # \dontrun{
# Download metadata (uses cache if available)
metadata <- download_metadata()

# Force update of metadata
metadata <- download_metadata(force_update = TRUE)
} # }
```
