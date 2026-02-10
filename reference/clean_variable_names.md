# Clean Variable Names

Cleans and standardizes variable names for consistency.

## Usage

``` r
clean_variable_names(names)
```

## Arguments

- names:

  Character vector of variable names

## Value

Character vector of cleaned names

## Examples

``` r
clean_variable_names(c("var.1", "var..2", "var...3"))
#> [1] "var.1" "var.2" "var.3"
```
