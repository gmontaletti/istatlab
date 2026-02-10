# Structured Logging Function

Provides timestamped logging consistent with reference implementation.
Output format: `YYYY-MM-DD HH:MM:SS TZ [LEVEL] - message`

## Usage

``` r
istat_log(msg, level = "INFO", verbose = TRUE)
```

## Arguments

- msg:

  Character message to log

- level:

  Character log level: one of "INFO", "WARNING", or "ERROR"

- verbose:

  Logical whether to output message

## Value

Invisible NULL
