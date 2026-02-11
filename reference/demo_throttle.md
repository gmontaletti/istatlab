# Throttle Demo API Requests

Enforces minimum delay between HTTP requests to demo.istat.it. Reads
rate limit settings from `get_istat_config()$demo_rate_limit` and uses a
separate state environment from the SDMX throttle.

## Usage

``` r
demo_throttle(config_override = NULL)
```

## Arguments

- config_override:

  Optional list to override demo_rate_limit config values. Must contain
  `delay` and `jitter_fraction` fields.

## Value

Invisible NULL
