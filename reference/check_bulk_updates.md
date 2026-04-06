# Check Multiple Datasets for Updates

Scans a vector of dataset codes against the ISTAT metadata endpoint to
determine which datasets have been updated since a given cutoff date.
Uses only lightweight dataflow metadata queries (no data is downloaded).
The result can be passed directly to
[`download_multiple_datasets`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md).

## Usage

``` r
check_bulk_updates(
  dataset_ids,
  cutoff = Sys.time() - 86400,
  api = getOption("istatlab.default_api", "legacy"),
  timeout = 30,
  verbose = TRUE
)
```

## Arguments

- dataset_ids:

  Character vector of ISTAT dataset codes (e.g.,
  `c("534_50", "150_908")`).

- cutoff:

  POSIXct timestamp. Datasets whose LAST_UPDATE is after this time are
  flagged as needing update. Default is 24 hours before
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

- api:

  Character string specifying the API surface. One of `"legacy"`
  (default), `"hvd_v1"`, or `"hvd_v2"`. Can be set session-wide via
  `options(istatlab.default_api = "hvd_v1")`.

- timeout:

  Numeric, seconds per metadata request. Default is 30.

- verbose:

  Logical indicating whether to print progress messages. Default is
  TRUE.

## Value

A character vector of dataset codes that need updating. Datasets where
the metadata check failed are included (conservative approach). The
vector has an attribute `"update_details"`: a `data.table` with columns
`dataset_id`, `last_update` (POSIXct or NA), and `status`
(`"needs_update"`, `"up_to_date"`, or `"check_failed"`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Check which datasets were updated in the last 24 hours
to_update <- check_bulk_updates(c("534_50", "150_908", "150_915"))

# Then download only those
if (length(to_update) > 0) {
  results <- download_multiple_datasets(to_update)
}

# Check with a custom cutoff (last week)
to_update <- check_bulk_updates(
  c("534_50", "150_908"),
  cutoff = Sys.time() - 7 * 86400
)

# Inspect details
attr(to_update, "update_details")
} # }
```
