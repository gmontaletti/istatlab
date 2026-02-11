# Build Demo URL for Pattern D (Category-Level)

Constructs URLs of the form
`{base_url}/previsioni/{DataType}-{GeoLevel}.zip`, used by forecast
datasets that publish static files keyed by data category and geographic
resolution rather than by year.

## Usage

``` r
build_demo_url_d(info, data_type, geo_level, base_url)
```

## Arguments

- info:

  Single-row data.table from the demo registry.

- data_type:

  Character string specifying the forecast data category.

- geo_level:

  Character string specifying the geographic resolution.

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Returns: "https://demo.istat.it/data/previsioni/Previsioni-Popolazione_per_eta-Regioni.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "prev", ][1L, ]
build_demo_url_d(info, data_type = "Previsioni-Popolazione_per_eta",
                 geo_level = "Regioni",
                 base_url = get_istat_config()$demo$base_url)
} # }
```
