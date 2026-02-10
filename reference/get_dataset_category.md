# Get Dataset Category

Returns datasets belonging to a specific category for easier
organization.

## Usage

``` r
get_dataset_category(category)
```

## Arguments

- category:

  Character string specifying the category ("employment",
  "unemployment", "job_vacancies", "labour_force")

## Value

Character vector of dataset IDs in the category

## Examples

``` r
if (FALSE) { # \dontrun{
# Get employment datasets
employment_datasets <- get_dataset_category("employment")

# Get all available categories
config <- get_istat_config()
categories <- names(config$dataset_categories)
} # }
```
