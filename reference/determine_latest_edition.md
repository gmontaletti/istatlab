# Determine Latest Edition

Identifies the edition code with the most recent date from a character
vector of ISTAT edition codes. Uses parsed dates rather than
alphabetical comparison to correctly handle edition ordering.

## Usage

``` r
determine_latest_edition(editions)
```

## Arguments

- editions:

  Character vector of unique ISTAT edition codes.

## Value

A single character string with the edition code corresponding to the
latest date.
