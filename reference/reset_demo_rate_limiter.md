# Reset Demo Rate Limiter State

Resets the internal rate limiter state for demo.istat.it requests.
Useful for testing or after switching between data sources.

## Usage

``` r
reset_demo_rate_limiter()
```

## Value

Invisible NULL

## Examples

``` r
if (FALSE) { # \dontrun{
# Reset demo rate limiter between sessions
reset_demo_rate_limiter()
} # }
```
