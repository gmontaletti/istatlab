# Detect Potential IP Ban

Checks if consecutive 429 responses indicate a likely IP ban.

## Usage

``` r
detect_ban(consecutive_429s, threshold)
```

## Arguments

- consecutive_429s:

  Integer count of consecutive 429 responses

- threshold:

  Integer ban detection threshold

## Value

Logical TRUE if ban is likely
