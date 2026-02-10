# Get ISTAT SDMX Service Configuration

Returns the configuration for ISTAT SDMX web service including all
available endpoints and cache settings based on the official service at
https://esploradati.istat.it/SDMXWS.

## Usage

``` r
get_istat_config()
```

## Value

A list containing ISTAT SDMX service configuration with the following
components:

- base_url: Base URL for ISTAT SDMX web service

- endpoints: List of available API endpoints

- defaults: Default settings for API calls

- dataset_categories: Organized dataset categories

## Examples

``` r
if (FALSE) { # \dontrun{
# Get service configuration
config <- get_istat_config()
print(config$endpoints$data)
print(config$cache$enabled)
} # }
```
