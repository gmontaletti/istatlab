# Parse Edition Date

Converts ISTAT edition codes (e.g., "G_2024_01", "G_2023_12") to Date
objects. Replaces G, M, and underscore characters with hyphens, pads
short dates with "-01", and converts to Date.

## Usage

``` r
parse_edition_date(edition_code)
```

## Arguments

- edition_code:

  Character vector of ISTAT edition codes.

## Value

A Date vector with the parsed dates.
