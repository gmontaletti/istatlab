# Ensure Codelists Are Available for Dataset

Checks if all codelists required by a dataset are in cache. Downloads
missing codelists before labeling operations. This prevents
apply_labels() from failing on new datasets.

## Usage

``` r
ensure_codelists(dataset_id, cache_dir = "meta", verbose = TRUE)
```

## Arguments

- dataset_id:

  Character, dataset ID to check

- cache_dir:

  Character, cache directory path. Default "meta"

- verbose:

  Logical, print status messages. Default TRUE

## Value

Logical, TRUE if all codelists are available (cached or downloaded)

## Examples

``` r
if (FALSE) { # \dontrun{
# Ensure codelists before labeling
if (ensure_codelists("534_50")) {
  labeled_data <- apply_labels(raw_data)
}

# Check new dataset
ensure_codelists("150_908", verbose = TRUE)
} # }
```
