# Get HVD Accept Header

Returns the appropriate HTTP `Accept` header value for the specified HVD
API version and response format. The SDMX content negotiation headers
differ between v1 (SDMX 2.1) and v2 (SDMX 3.0) for data responses.

## Usage

``` r
get_hvd_accept_header(api_version, format = "csv")
```

## Arguments

- api_version:

  Character string, either `"hvd_v1"` or `"hvd_v2"`.

- format:

  Character string specifying the desired response format. One of
  `"csv"` (default), `"json"`, or `"xml"`.

## Value

Character string containing the Accept header value.

## Examples

``` r
if (FALSE) { # \dontrun{
# CSV headers
get_hvd_accept_header("hvd_v1", "csv")
# "application/vnd.sdmx.data+csv;version=1.0.0"

get_hvd_accept_header("hvd_v2", "csv")
# "application/vnd.sdmx.data+csv;version=2.0.0"

# JSON headers
get_hvd_accept_header("hvd_v1", "json")
# "application/vnd.sdmx.data+json;version=1.0.0"

get_hvd_accept_header("hvd_v2", "json")
# "application/vnd.sdmx.data+json;version=2.0.0"
} # }
```
