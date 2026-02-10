# Get Available Frequencies for Dataset

Queries the availableconstraint endpoint to determine which frequencies
(A=Annual, Q=Quarterly, M=Monthly) are available for a dataset.

## Usage

``` r
get_available_frequencies(dataset_id, timeout = 30)
```

## Arguments

- dataset_id:

  Character string specifying dataset ID

- timeout:

  Numeric timeout in seconds. Default 30

## Value

Character vector of available frequency codes (e.g., c("A", "Q")), or
NULL if request fails

## Examples

``` r
if (FALSE) { # \dontrun{
# Get available frequencies for unemployment dataset
freqs <- get_available_frequencies("151_914")
# Returns: c("A", "Q")
} # }
```
