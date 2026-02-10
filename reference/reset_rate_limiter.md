# Reset Rate Limiter State

Resets the internal rate limiter state. Useful for testing or after an
IP ban has expired.

## Usage

``` r
reset_rate_limiter()
```

## Value

Invisible NULL

## Examples

``` r
if (FALSE) { # \dontrun{
# Reset after ban period
reset_rate_limiter()
} # }
```
