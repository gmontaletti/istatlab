# Get Codelists Used by Dataset

Retrieves the list of codelist IDs used by a specific dataset from the
cache.

## Usage

``` r
get_dataset_codelists(dataset_id, cache_dir = "meta")
```

## Arguments

- dataset_id:

  Character string specifying the dataset ID

- cache_dir:

  Character string specifying the cache directory

## Value

Character vector of codelist IDs (e.g., c("CL_FREQ", "CL_ITTER107")), or
NULL if dataset not found in cache

## Examples

``` r
if (FALSE) { # \dontrun{
# Get codelists for a dataset
codelists <- get_dataset_codelists("534_50")
# Returns: c("CL_FREQ", "CL_ITTER107", "CL_ATECO_2007", ...)
} # }
```
