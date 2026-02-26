# Get HVD API Information

Returns a summary of the ISTAT HVD (High-Value Datasets) API
capabilities for both the v1 (SDMX 2.1) and v2 (SDMX 3.0) interfaces.
Useful for checking available endpoints, supported methods, and
stability status.

## Usage

``` r
get_hvd_info()
```

## Value

A list with two elements:

- v1:

  List with `base_url`, `status`, `sdmx_version`, `methods`, and
  `description` for the SDMX 2.1 interface

- v2:

  List with `base_url`, `status`, `sdmx_version`, `methods`, and
  `description` for the SDMX 3.0 interface

## Examples

``` r
info <- get_hvd_info()
info$v1$base_url
#> [1] "https://esploradati.istat.it/hvd"
info$v2$status
#> [1] "experimental"
```
