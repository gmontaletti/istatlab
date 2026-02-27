# Get HVD Accept Header

Returns the appropriate HTTP `Accept` header value for the specified HVD
API version, content type, and response format. Data endpoints use
SDMX-specific media types (`application/vnd.sdmx.data+{format}`).
Structure endpoints use generic media types (`application/json`,
`application/xml`, `text/csv`) because the HVD server rejects
SDMX-specific Accept headers on structure endpoints with HTTP 406.

## Usage

``` r
get_hvd_accept_header(api_version, format = "csv", type = "data")
```

## Arguments

- api_version:

  Character string, either `"hvd_v1"` or `"hvd_v2"`.

- format:

  Character string specifying the desired response format. One of
  `"csv"` (default), `"json"`, or `"xml"`.

- type:

  Character string specifying the content type category. One of `"data"`
  (default) for data retrieval endpoints, or `"structure"` for metadata
  and structure definition endpoints (dataflow listing, DSD retrieval,
  available values). Default `"data"` preserves backward compatibility.

## Value

Character string containing the Accept header value.

## Examples

``` r
if (FALSE) { # \dontrun{
# Data headers (default)
get_hvd_accept_header("hvd_v1", "csv")
# "application/vnd.sdmx.data+csv;version=1.0.0"

get_hvd_accept_header("hvd_v2", "json")
# "application/vnd.sdmx.data+json;version=2.0.0"

# Structure headers for metadata endpoints (generic)
get_hvd_accept_header("hvd_v1", "json", type = "structure")
# "application/json"

get_hvd_accept_header("hvd_v2", "json", type = "structure")
# "application/json"
} # }
```
