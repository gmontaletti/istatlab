# Download Codelists

Downloads codelists for ISTAT datasets using a deduplicated cache
structure. Codelists are stored by their ID (e.g., CL_FREQ) rather than
by dataset, reducing redundant storage since many codelists are shared
across datasets.

## Usage

``` r
download_codelists(
  dataset_ids = NULL,
  force_update = FALSE,
  cache_dir = .istatlab_cache_dir()
)
```

## Arguments

- dataset_ids:

  Character vector of dataset IDs. If NULL, downloads for all available
  datasets

- force_update:

  Logical indicating whether to force update of cached codelists

- cache_dir:

  Character string specifying the directory for caching codelists

## Value

A named list of codelists keyed by dataset ID (e.g., "X534_50"), where
each element is a data.table with codelist information

## Details

The default cache directory is resolved from the `ISTATLAB_CACHE_DIR`
environment variable
(`Sys.getenv("ISTATLAB_CACHE_DIR", unset = "meta")`). Set this variable,
for example in `.Renviron`, to share a single metadata cache across
multiple projects; when unset, the local `"meta"` directory is used.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download codelists for specific datasets
codelists <- download_codelists(c("150_908", "150_915"))

# Download all available codelists
all_codelists <- download_codelists()
} # }
```
