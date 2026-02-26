# List Available HVD Dataflows

Retrieves the catalogue of all dataflows published on the ISTAT
Historical Data Vault. Each dataflow corresponds to a downloadable
dataset with its own data structure definition.

## Usage

``` r
list_hvd_dataflows(api_version = "hvd_v1", timeout = 120, verbose = TRUE)
```

## Arguments

- api_version:

  Character string indicating the API surface to use. One of `"hvd_v1"`
  (default) or `"hvd_v2"`.

- timeout:

  Numeric timeout in seconds for the HTTP request. Default 120.

- verbose:

  Logical controlling structured logging output. Default TRUE.

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns `id`, `name`, `description`, and `agency`, or `NULL` if the
request fails. A warning is issued on failure.

## Examples

``` r
if (FALSE) { # \dontrun{
# List all HVD dataflows using the v1 API
flows <- list_hvd_dataflows()
print(flows)

# List dataflows using the v2 API
flows_v2 <- list_hvd_dataflows(api_version = "hvd_v2")
} # }
```
