# List Demographic Datasets from Demo.istat.it

Returns a summary table of all available demographic datasets from
demo.istat.it, optionally filtered by thematic category.

## Usage

``` r
list_demo_datasets(category = NULL)
```

## Arguments

- category:

  Optional character string specifying a thematic category to filter by
  (e.g., `"popolazione"`, `"dinamica"`, `"matrimoni"`). If `NULL`
  (default), all datasets are returned. Use
  [`get_demo_categories`](https://gmontaletti.github.io/istatlab/reference/get_demo_categories.md)
  to see valid categories.

## Value

A `data.table` with columns: `code`, `category`, `description_it`,
`description_en`, `url_pattern`, `downloadable`.

## Examples

``` r
# List all demographic datasets
all_datasets <- list_demo_datasets()
print(all_datasets)
#>       code      category                                   description_it
#>     <char>        <char>                                           <char>
#>  1:    D7B      dinamica                     Bilancio demografico mensile
#>  2:    RBD   popolazione       Bilancio demografico ricostruito 2002-2019
#>  3:    AIR      dinamica             Italiani residenti all'estero (AIRE)
#>  4:    POS   popolazione           Popolazione residente per eta' e sesso
#>  5:    STR   popolazione Popolazione straniera residente per eta' e sesso
#>  6:    P02      dinamica                     Bilancio demografico annuale
#>  7:    P03      dinamica                   Bilancio demografico stranieri
#>  8:    TVM    indicatori                             Tavole di mortalita'
#>  9:    PPR    previsioni           Previsioni della popolazione residente
#> 10:    PPC    previsioni            Previsioni della popolazione comunale
#> 11:    RIC   popolazione      Popolazione residente ricostruita 2002-2019
#> 12:    PRF    previsioni                        Previsioni delle famiglie
#> 13:    RCS   popolazione           Popolazione residente per cittadinanza
#> 14:    TVA    indicatori                  Tavole attuariali di mortalita'
#> 15:    ISM     mortalita                           Cancellati per decesso
#> 16:    R91      dinamica                   Bilancio demografico 1991-2001
#> 17:    R92   popolazione                  Popolazione residente 1992-2001
#> 18:    FE1      natalita                         Indicatori di fecondita'
#> 19:    FE3      natalita                                  Nati per comune
#> 20:    SSC   popolazione     Popolazione semi-supercentenaria (105+ anni)
#> 21:    MA1     matrimoni             Matrimoni - indicatori di nuzialita'
#> 22:    MA2     matrimoni          Matrimoni - caratteristiche degli sposi
#> 23:    MA3     matrimoni           Matrimoni per cittadinanza degli sposi
#> 24:    MA4     matrimoni                       Matrimoni - serie storiche
#> 25:    NU1     matrimoni                       Tavole di primo-nuzialita'
#> 26:    UC1 unioni_civili            Unioni civili - principali indicatori
#> 27:    UC2 unioni_civili                  Unioni civili - caratteristiche
#> 28:    UC3 unioni_civili                     Unioni civili - cittadinanza
#> 29:    UC4 unioni_civili                   Unioni civili - serie storiche
#> 30:    PFL    previsioni                 Previsioni delle forze di lavoro
#>       code      category                                   description_it
#>     <char>        <char>                                           <char>
#>                                    description_en url_pattern downloadable
#>                                            <char>      <char>       <lgcl>
#>  1:                   Monthly demographic balance           A         TRUE
#>  2:   Reconstructed demographic balance 2001-2018           A         TRUE
#>  3:      Italians residing abroad (AIRE registry)          A1         TRUE
#>  4:            Resident population by age and sex           B         TRUE
#>  5:    Foreign resident population by age and sex           B         TRUE
#>  6:                    Annual demographic balance           B         TRUE
#>  7:        Foreign population demographic balance           B         TRUE
#>  8:                Life tables (mortality tables)           C         TRUE
#>  9:               Resident population projections           D         TRUE
#> 10:              Municipal population projections           D         TRUE
#> 11:   Reconstructed resident population 2002-2019           D         TRUE
#> 12:                         Household projections           D         TRUE
#> 13:            Resident population by citizenship           E         TRUE
#> 14:                    Actuarial mortality tables           F         TRUE
#> 15:               Deaths (cancelled due to death)           G         TRUE
#> 16:                 Demographic balance 1991-2001        <NA>        FALSE
#> 17:                 Resident population 1992-2001        <NA>        FALSE
#> 18:                          Fertility indicators        <NA>        FALSE
#> 19:                        Births by municipality        <NA>        FALSE
#> 20: Semi-supercentenarian population (105+ years)        <NA>        FALSE
#> 21:             Marriages - nuptiality indicators        <NA>        FALSE
#> 22:        Marriages - characteristics of spouses        <NA>        FALSE
#> 23:           Marriages by citizenship of spouses        <NA>        FALSE
#> 24:            Marriages - historical time series        <NA>        FALSE
#> 25:                       First-nuptiality tables        <NA>        FALSE
#> 26:                Civil unions - main indicators        <NA>        FALSE
#> 27:                Civil unions - characteristics        <NA>        FALSE
#> 28:                    Civil unions - citizenship        <NA>        FALSE
#> 29:         Civil unions - historical time series        <NA>        FALSE
#> 30:                      Labour force projections        <NA>        FALSE
#>                                    description_en url_pattern downloadable
#>                                            <char>      <char>       <lgcl>

# List only population datasets
pop_datasets <- list_demo_datasets(category = "popolazione")

# List marriage-related datasets
marriage_datasets <- list_demo_datasets(category = "matrimoni")
```
