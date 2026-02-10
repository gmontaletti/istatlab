# Test ISTAT Endpoint Connectivity

Tests connectivity to ISTAT SDMX endpoints using lightweight HTTP status
checks.

## Usage

``` r
test_endpoint_connectivity(endpoints = "data", timeout = 30, verbose = TRUE)
```

## Arguments

- endpoints:

  Character vector of endpoint names to test (default "data").
  Available: "data", "dataflow", "datastructure", "codelist",
  "registry", "availableconstraint"

- timeout:

  Numeric timeout in seconds for each test (default 30)

- verbose:

  Logical for detailed output

## Value

A data.frame with connectivity test results including: endpoint, url,
accessible, status_code, response_time, error_message

## Examples

``` r
if (FALSE) { # \dontrun{
# Quick connectivity check (default: data endpoint only)
status <- test_endpoint_connectivity()

# Test multiple endpoints
status <- test_endpoint_connectivity(c("data", "dataflow"))
} # }
```
