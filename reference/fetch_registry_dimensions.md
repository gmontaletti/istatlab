# Get Dataset Dimensions from Registry Endpoint

Retrieves dataset dimensions using the ISTAT SDMX registry capabilities.

## Usage

``` r
fetch_registry_dimensions(dataset_id)
```

## Arguments

- dataset_id:

  Character string specifying dataset ID

## Value

A list of dataset dimensions

## Examples

``` r
if (FALSE) { # \dontrun{
# Get dimensions for employment dataset
dims <- fetch_registry_dimensions("150_908")
} # }
```
