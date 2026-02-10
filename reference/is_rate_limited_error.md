# Check if Error is Rate Limiting

Detects HTTP 429 and rate limiting errors from messages.

## Usage

``` r
is_rate_limited_error(error_message)
```

## Arguments

- error_message:

  Character string containing error message

## Value

Logical indicating if error is rate-limit-related
