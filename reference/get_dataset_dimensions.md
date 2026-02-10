# Get Dataset Dimensions

Retrieves the dimension names (codelists) for a specific ISTAT dataset
by querying the datastructure endpoint.

## Usage

``` r
get_dataset_dimensions(dataset_id)
```

## Arguments

- dataset_id:

  Character string specifying the dataset ID

## Value

A character vector of dimension/codelist names for the dataset, or NULL
if the dataset is not found or an error occurs

## Examples

``` r
if (FALSE) { # \dontrun{
# Get dimensions for a dataset
dims <- get_dataset_dimensions("534_50")
# Returns: c("ATECO_2007", "BASE_YEAR", "CORREZ", "FREQ", ...)
} # }
```
