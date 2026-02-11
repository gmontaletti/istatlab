# Load Metadata from Cache

Loads codelists and variable dimensions from the deduplicated cache
structure. Codelists are stored by codelist ID (e.g., CL_FREQ) and
reassembled per-dataset for backward compatibility with apply_labels().

## Usage

``` r
load_metadata_cached(
  codelists = NULL,
  var_dimensions = NULL,
  cache_dir = "meta"
)
```

## Arguments

- codelists:

  Optional pre-loaded codelists. If NULL, loads from cache

- var_dimensions:

  Optional pre-loaded variable dimensions. If NULL, loads from cache

- cache_dir:

  Character string specifying cache directory

## Value

List with codelists (keyed by dataset) and var_dimensions
