# Get Available Editions for Dataset

Queries the availableconstraint endpoint to determine which edition
codes are available for a dataset. Not all datasets have an EDITION
dimension; for those that do not, this function returns NULL without
warning.

## Usage

``` r
get_available_editions(dataset_id, timeout = 30)
```

## Arguments

- dataset_id:

  Character string specifying dataset ID

- timeout:

  Numeric timeout in seconds. Default 30

## Value

Character vector of available edition codes (e.g.,
`c("G_2024_01", "G_2023_12")`), or NULL if the dataset does not have an
EDITION dimension or the request fails

## Examples

``` r
if (FALSE) { # \dontrun{
# Get available editions for a dataset
editions <- get_available_editions("150_908")
# Returns: c("G_2024_01", "G_2023_12", ...) or NULL
} # }
```
