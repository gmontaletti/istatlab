# Get HVD Accept Header

Returns the appropriate HTTP `Accept` header value for the specified HVD
API version, content type, and response format. The SDMX standard uses
distinct media types for data and structure endpoints:

- Data endpoints: `application/vnd.sdmx.data+{format}`

- Structure endpoints: `application/vnd.sdmx.structure+{format}`

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

## Details

The version suffix differs between SDMX 2.1 (`1.0.0`) and SDMX 3.0
(`2.0.0`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Data headers (default)
get_hvd_accept_header("hvd_v1", "csv")
# "application/vnd.sdmx.data+csv;version=1.0.0"

get_hvd_accept_header("hvd_v2", "json")
# "application/vnd.sdmx.data+json;version=2.0.0"

# Structure headers for metadata endpoints
get_hvd_accept_header("hvd_v1", "json", type = "structure")
# "application/vnd.sdmx.structure+json;version=1.0.0"

get_hvd_accept_header("hvd_v2", "json", type = "structure")
# "application/vnd.sdmx.structure+json;version=2.0.0"
} # }
```
