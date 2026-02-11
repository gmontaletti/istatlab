# Check Whether a Cached Demo File Needs Re-downloading

Determines if a locally cached file should be refreshed by comparing the
server's `Last-Modified` header (via
[`http_head_demo()`](https://gmontaletti.github.io/istatlab/reference/http_head_demo.md))
with the file's modification time. When the HEAD request fails or the
server does not provide a `Last-Modified` header, the function falls
back to an age-based check using
`get_istat_config()$demo$cache_max_age_days`.

## Usage

``` r
check_demo_update(url, cached_file_path, verbose = TRUE)
```

## Arguments

- url:

  Character string with the remote URL of the file.

- cached_file_path:

  Character string with the local path to the cached file.

- verbose:

  Logical whether to log status messages. Default `TRUE`.

## Value

A list with components:

- needs_update:

  Logical indicating if a re-download is needed.

- reason:

  Character string describing the decision: `"not_cached"`,
  `"server_newer"`, `"up_to_date"`, `"age_exceeded"`, or
  `"within_age_limit"`.

## Examples

``` r
if (FALSE) { # \dontrun{
status <- check_demo_update(
  url = "https://demo.istat.it/data/d7b/D7B2024.csv.zip",
  cached_file_path = "demo_data/d7b/D7B2024.csv.zip"
)
if (status$needs_update) message("Re-download required: ", status$reason)
} # }
```
