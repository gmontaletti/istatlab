# Search Demographic Datasets by Keyword

Searches the demo.istat.it dataset registry by matching a keyword
against one or more text fields. Useful for locating datasets when the
exact code or category is not known.

## Usage

``` r
search_demo_datasets(
  keyword,
  fields = c("description_it", "description_en", "code"),
  ignore_case = TRUE
)
```

## Arguments

- keyword:

  Character string containing the search term.

- fields:

  Character vector of column names to search in. Default is
  `c("description_it", "description_en", "code")`.

- ignore_case:

  Logical indicating whether the search should be case-insensitive.
  Default is `TRUE`.

## Value

A `data.table` with matching rows, containing columns: `code`,
`category`, `description_it`, `description_en`, `url_pattern`,
`downloadable`.

## Examples

``` r
# Search for population-related datasets
search_demo_datasets("popolazione")
#>      code    category                                   description_it
#>    <char>      <char>                                           <char>
#> 1:    POS popolazione           Popolazione residente per eta' e sesso
#> 2:    STR popolazione Popolazione straniera residente per eta' e sesso
#> 3:    PPR  previsioni           Previsioni della popolazione residente
#> 4:    PPC  previsioni            Previsioni della popolazione comunale
#> 5:    RIC popolazione      Popolazione residente ricostruita 2002-2019
#> 6:    RCS popolazione           Popolazione residente per cittadinanza
#> 7:    R92 popolazione                  Popolazione residente 1992-2001
#> 8:    SSC popolazione     Popolazione semi-supercentenaria (105+ anni)
#>                                   description_en url_pattern downloadable
#>                                           <char>      <char>       <lgcl>
#> 1:            Resident population by age and sex           B         TRUE
#> 2:    Foreign resident population by age and sex           B         TRUE
#> 3:               Resident population projections           D         TRUE
#> 4:              Municipal population projections           D         TRUE
#> 5:   Reconstructed resident population 2002-2019           D         TRUE
#> 6:            Resident population by citizenship           E         TRUE
#> 7:                 Resident population 1992-2001        <NA>        FALSE
#> 8: Semi-supercentenarian population (105+ years)        <NA>        FALSE

# Search in English descriptions only
search_demo_datasets("mortality", fields = "description_en")
#>      code   category                  description_it
#>    <char>     <char>                          <char>
#> 1:    TVM indicatori            Tavole di mortalita'
#> 2:    TVA indicatori Tavole attuariali di mortalita'
#>                    description_en url_pattern downloadable
#>                            <char>      <char>       <lgcl>
#> 1: Life tables (mortality tables)           C         TRUE
#> 2:     Actuarial mortality tables           F         TRUE

# Case-sensitive search
search_demo_datasets("AIRE", ignore_case = FALSE)
#>      code category                       description_it
#>    <char>   <char>                               <char>
#> 1:    AIR dinamica Italiani residenti all'estero (AIRE)
#>                              description_en url_pattern downloadable
#>                                      <char>      <char>       <lgcl>
#> 1: Italians residing abroad (AIRE registry)          A1         TRUE
```
