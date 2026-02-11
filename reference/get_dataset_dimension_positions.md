# Get Dataset Dimension Positions

Retrieves the dimension names and their SDMX key positions for a
specific ISTAT dataset. Positions indicate the order of dimensions in
the SDMX key (1-based), which is needed for constructing data queries
with positional filters.

## Usage

``` r
get_dataset_dimension_positions(dataset_id)
```

## Arguments

- dataset_id:

  Character string specifying the dataset ID

## Value

A named integer vector mapping dimension IDs to their 1-based positions
(e.g., `c(FREQ = 1L, REF_AREA = 2L, EDITION = 7L)`), or NULL if the
dataset is not found or an error occurs

## Examples

``` r
if (FALSE) { # \dontrun{
# Get dimension positions for a dataset
positions <- get_dataset_dimension_positions("534_50")
# Returns: c(ATECO_2007 = 1L, BASE_YEAR = 2L, CORREZ = 3L, ...)

# Use positions to identify the FREQ dimension slot
freq_pos <- positions["FREQ"]
} # }
```
