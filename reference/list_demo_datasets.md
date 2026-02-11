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
`description_en`, `url_pattern`.

## Examples

``` r
# List all demographic datasets
all_datasets <- list_demo_datasets()
print(all_datasets)
#>       code      category                                   description_it
#>     <char>        <char>                                           <char>
#>  1:    D7B      dinamica                     Bilancio demografico mensile
#>  2:    P02      dinamica                     Bilancio demografico annuale
#>  3:    P03      dinamica                   Bilancio demografico stranieri
#>  4:    RBD      dinamica       Bilancio demografico ricostruito 2002-2019
#>  5:    R91      dinamica                   Bilancio demografico 1991-2001
#>  6:    AIR      dinamica             Italiani residenti all'estero (AIRE)
#>  7:    FE1      natalita                         Indicatori di fecondita'
#>  8:    FE3      natalita                                  Nati per comune
#>  9:    ISM     mortalita                           Cancellati per decesso
#> 10:    RIC   popolazione      Popolazione residente ricostruita 2002-2019
#> 11:    R92   popolazione                  Popolazione residente 1992-2001
#> 12:    SSC   popolazione     Popolazione semi-supercentenaria (105+ anni)
#> 13:    MA1     matrimoni             Matrimoni - indicatori di nuzialita'
#> 14:    MA2     matrimoni          Matrimoni - caratteristiche degli sposi
#> 15:    MA3     matrimoni           Matrimoni per cittadinanza degli sposi
#> 16:    MA4     matrimoni                       Matrimoni - serie storiche
#> 17:    NU1     matrimoni                       Tavole di primo-nuzialita'
#> 18:    UC1 unioni_civili            Unioni civili - principali indicatori
#> 19:    UC2 unioni_civili                  Unioni civili - caratteristiche
#> 20:    UC3 unioni_civili                     Unioni civili - cittadinanza
#> 21:    UC4 unioni_civili                   Unioni civili - serie storiche
#> 22:    POS   popolazione           Popolazione residente per eta' e sesso
#> 23:    STR   popolazione Popolazione straniera residente per eta' e sesso
#> 24:    RCS   popolazione           Popolazione residente per cittadinanza
#> 25:    TVM    indicatori                             Tavole di mortalita'
#> 26:    TVA    indicatori                  Tavole attuariali di mortalita'
#> 27:    PPR    previsioni           Previsioni della popolazione residente
#> 28:    PRF    previsioni                        Previsioni delle famiglie
#> 29:    PPC    previsioni            Previsioni della popolazione comunale
#> 30:    PFL    previsioni                 Previsioni delle forze di lavoro
#>       code      category                                   description_it
#>     <char>        <char>                                           <char>
#>                                    description_en url_pattern
#>                                            <char>      <char>
#>  1:                   Monthly demographic balance           A
#>  2:                    Annual demographic balance           A
#>  3:        Foreign population demographic balance           A
#>  4:   Reconstructed demographic balance 2002-2019           A
#>  5:                 Demographic balance 1991-2001           A
#>  6:      Italians residing abroad (AIRE registry)           A
#>  7:                          Fertility indicators           A
#>  8:                        Births by municipality           A
#>  9:               Deaths (cancelled due to death)           A
#> 10:   Reconstructed resident population 2002-2019           A
#> 11:                 Resident population 1992-2001           A
#> 12: Semi-supercentenarian population (105+ years)           A
#> 13:             Marriages - nuptiality indicators           A
#> 14:        Marriages - characteristics of spouses           A
#> 15:           Marriages by citizenship of spouses           A
#> 16:            Marriages - historical time series           A
#> 17:                       First-nuptiality tables           A
#> 18:                Civil unions - main indicators           A
#> 19:                Civil unions - characteristics           A
#> 20:                    Civil unions - citizenship           A
#> 21:         Civil unions - historical time series           A
#> 22:            Resident population by age and sex           B
#> 23:    Foreign resident population by age and sex           B
#> 24:            Resident population by citizenship           B
#> 25:                Life tables (mortality tables)           C
#> 26:                    Actuarial mortality tables           C
#> 27:               Resident population projections           D
#> 28:                         Household projections           D
#> 29:              Municipal population projections           D
#> 30:                      Labour force projections           D
#>                                    description_en url_pattern
#>                                            <char>      <char>

# List only population datasets
pop_datasets <- list_demo_datasets(category = "popolazione")

# List marriage-related datasets
marriage_datasets <- list_demo_datasets(category = "matrimoni")
```
