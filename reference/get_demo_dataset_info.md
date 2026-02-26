# Get Detailed Information for a Demographic Dataset

Returns the full registry row for a single dataset identified by its
short code. All metadata columns are included (territories, levels,
types, etc.).

## Usage

``` r
get_demo_dataset_info(code)
```

## Arguments

- code:

  Character string with the dataset code (e.g., `"D7B"`, `"POS"`,
  `"TVM"`, `"PPR"`).

## Value

A single-row `data.table` with all registry columns for the requested
dataset.

## Examples

``` r
# Get info for the monthly demographic balance
info <- get_demo_dataset_info("D7B")
print(info)
#>      code url_pattern base_path file_code category               description_it
#>    <char>      <char>    <char>    <char>   <char>                       <char>
#> 1:    D7B           A       d7b       D7B dinamica Bilancio demografico mensile
#>                 description_en year_start year_end downloadable territories
#>                         <char>      <int>    <int>       <lgcl>      <char>
#> 1: Monthly demographic balance       2019       NA         TRUE        <NA>
#>    levels  types data_types geo_levels file_extension subtypes static_filename
#>    <char> <char>     <char>     <char>         <char>   <char>          <char>
#> 1:   <NA>   <NA>       <NA>       <NA>           <NA>     <NA>            <NA>

# Get info for resident population by age and sex
info <- get_demo_dataset_info("POS")
print(info$territories)
#> [1] "Comuni,Province,Regioni,Ripartizioni"
```
