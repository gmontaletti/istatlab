# Check Endpoint HTTP Status

Lightweight connectivity check using httr. Fetches only response headers
(status code) without downloading body.

## Usage

``` r
check_endpoint_status(url, timeout = 10)
```

## Arguments

- url:

  Character URL to check

- timeout:

  Numeric timeout in seconds (default 10)

## Value

A list with accessible (logical), status_code, response_time, error
