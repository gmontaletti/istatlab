# Test HVD Endpoint Connectivity

Performs lightweight HEAD-only requests against HVD API endpoints to
verify that the service is reachable. Tests both data and structure
endpoints for each requested API version.

## Usage

``` r
test_hvd_connectivity(version = c("v1", "v2"), timeout = 30, verbose = TRUE)
```

## Arguments

- version:

  Character vector specifying which API versions to test. Valid values
  are `"v1"` and `"v2"`. Defaults to `c("v1", "v2")`, which tests both.

- timeout:

  Numeric timeout in seconds for each individual connectivity check.
  Default 30.

- verbose:

  Logical controlling structured logging and summary output. Default
  TRUE.

## Value

A data.frame with one row per tested endpoint and the following columns:

- version:

  Character. API version (`"v1"` or `"v2"`).

- endpoint:

  Character. Endpoint type (`"data"` or `"structure"`).

- url:

  Character. Full URL that was tested.

- accessible:

  Logical. Whether the endpoint responded successfully.

- status_code:

  Integer. HTTP status code, or `NA` on connection failure.

- response_time:

  Numeric. Round-trip time in seconds.

- error_message:

  Character. Error description, or empty string on success.

## Examples

``` r
if (FALSE) { # \dontrun{
# Test both v1 and v2 endpoints
status <- test_hvd_connectivity()

# Test only v1 endpoints
status <- test_hvd_connectivity(version = "v1")

# Test with a shorter timeout
status <- test_hvd_connectivity(timeout = 10, verbose = FALSE)
} # }
```
