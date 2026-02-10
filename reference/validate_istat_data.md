# Validate ISTAT Data

Validates the structure and content of ISTAT data.

## Usage

``` r
validate_istat_data(data, required_cols = c("ObsDimension", "ObsValue"))
```

## Arguments

- data:

  A data.table to validate

- required_cols:

  Character vector of required column names

## Value

Logical indicating if data is valid

## Examples

``` r
if (FALSE) { # \dontrun{
is_valid <- validate_istat_data(my_data, c("tempo", "valore"))
} # }
```
