# Get Dataset Information by Category

Returns organized dataset information grouped by statistical categories.

## Usage

``` r
get_categorized_datasets(category = NULL)
```

## Arguments

- category:

  Optional character string to filter by category

## Value

A list containing dataset IDs organized by category

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all categorized datasets
all_categories <- get_categorized_datasets()

# Get just employment datasets
employment <- get_categorized_datasets("employment")
} # }
```
