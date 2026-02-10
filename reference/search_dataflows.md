# Search Dataflows by Keywords

Searches available dataflows using keywords in Italian and English.

## Usage

``` r
search_dataflows(
  keywords,
  fields = c("Name.it", "Name.en", "id"),
  ignore_case = TRUE
)
```

## Arguments

- keywords:

  Character vector of search terms

- fields:

  Character vector of fields to search in. Default searches Name.it
  (Italian), Name.en (English), and id

- ignore_case:

  Logical indicating case-insensitive search. Default TRUE

## Value

A filtered data.table of matching dataflows

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for employment-related datasets (Italian)
lavoro_datasets <- search_dataflows("lavoro")

# Search for employment-related datasets (multiple terms)
employment_datasets <- search_dataflows(c("employment", "lavoro", "occupazione"))

# Search unemployment datasets
unemployment_datasets <- search_dataflows(c("unemployment", "disoccupazione"))

# Search only in dataset IDs
datasets_534 <- search_dataflows("534", fields = "id")
} # }
```
