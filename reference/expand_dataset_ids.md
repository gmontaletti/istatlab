# Expand Dataset IDs to Include All Matching Variants

Expands root dataset IDs to include all related datasets from metadata.
For example: "534_49" expands to c("534_49", "534_49_DF_DCSC_GI_ORE_10",
...)

## Usage

``` r
expand_dataset_ids(dataset_codes, metadata = NULL, expand = TRUE)
```

## Arguments

- dataset_codes:

  Character vector of dataset codes to expand

- metadata:

  Optional data.table with metadata (fetched if NULL)

- expand:

  Logical, if FALSE returns codes unchanged (default TRUE)

## Value

Character vector with all matching dataset IDs

## Examples

``` r
if (FALSE) { # \dontrun{
# Expand single code
ids <- expand_dataset_ids("534_49")
# Returns: c("534_49", "534_49_DF_DCSC_GI_ORE_10", ...)

# Expand multiple codes
ids <- expand_dataset_ids(c("534_49", "155_318"))

# Disable expansion
ids <- expand_dataset_ids("534_49", expand = FALSE)
# Returns: "534_49"
} # }
```
