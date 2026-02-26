# Validate API Surface Identifier

Checks that the supplied API surface identifier is one of the three
supported values: `"legacy"` (the existing SDMX 2.1 service at
`esploradati.istat.it/SDMXWS`), `"hvd_v1"` (HVD SDMX 2.1), or `"hvd_v2"`
(HVD SDMX 3.0). Stops with an informative error when an unrecognized
value is provided.

## Usage

``` r
validate_api_surface(api)
```

## Arguments

- api:

  Character string identifying the API surface. Must be one of
  `"legacy"`, `"hvd_v1"`, or `"hvd_v2"`.

## Value

The validated `api` string, returned invisibly. This allows the function
to be used inline: `api <- validate_api_surface(api)`.

## Examples

``` r
validate_api_surface("legacy")
validate_api_surface("hvd_v1")
validate_api_surface("hvd_v2")

if (FALSE) { # \dontrun{
# Triggers an error
validate_api_surface("v3")
} # }
```
