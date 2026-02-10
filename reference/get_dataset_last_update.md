# Get Dataset Last Update Timestamp from ISTAT API

Fetches the LAST_UPDATE timestamp from the ISTAT dataflow endpoint for a
specific dataset. This timestamp indicates when ISTAT last updated the
dataset and can be used to determine if cached data needs refreshing.

## Usage

``` r
get_dataset_last_update(dataset_id, timeout = 30)
```

## Arguments

- dataset_id:

  Character string specifying the dataset ID

- timeout:

  Numeric timeout in seconds for the API request. Default 30

## Value

POSIXct timestamp of the last update, or NULL if not available

## Examples

``` r
if (FALSE) { # \dontrun{
# Get last update timestamp for a dataset
last_update <- get_dataset_last_update("534_50")
# Returns: POSIXct "2025-12-17 10:06:46 UTC"
} # }
```
