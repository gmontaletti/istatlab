# Get HVD Base URL

Returns the base URL for the ISTAT HVD (High Value Datasets) service.
Both HVD v1 and HVD v2 share the same base URL; the version-specific
path prefix (`/rest/` vs `/rest/v2/`) is appended by the respective URL
builders.

## Usage

``` r
get_hvd_base_url()
```

## Value

Character string containing the HVD base URL.
