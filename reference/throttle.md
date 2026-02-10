# Throttle API Requests

Enforces minimum delay between HTTP requests to respect ISTAT rate
limits. Adds jitter to prevent synchronized request patterns.

## Usage

``` r
throttle(config_override = NULL)
```

## Arguments

- config_override:

  Optional list to override rate_limit config values

## Value

Invisible NULL
