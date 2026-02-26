# Build Demo URL for Pattern D (Datatype-Geolevel)

Constructs URLs of the form
`{base_url}/{base_path}/{DataType}-{GeoLevel}{ext}` or
`{base_url}/{base_path}/{DataType}{ext}` (when no geo_level applies),
used by forecast and reconstruction datasets that publish static files
keyed by data category and optional geographic resolution.

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

  Character string specifying the geographic resolution. May be `NULL`
  for datasets that have no geographic segmentation.

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# With geo_level:
# Returns: "https://demo.istat.it/data/previsioni/Previsioni-Popolazione_per_eta-Regioni.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "PPR", ][1L, ]
build_demo_url_d(info, data_type = "Previsioni-Popolazione_per_eta",
                 geo_level = "Regioni",
                 base_url = get_istat_config()$demo$base_url)

# Without geo_level:
# Returns: "https://demo.istat.it/data/previsionifamiliari/Famiglie_per_tipologia_familiare.csv.zip"
info <- registry[registry$code == "PRF", ][1L, ]
build_demo_url_d(info, data_type = "Famiglie_per_tipologia_familiare",
                 geo_level = NULL,
                 base_url = get_istat_config()$demo$base_url)
} # }
```
