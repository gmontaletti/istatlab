# Build Demo URL for Pattern A1 (Year + Locale)

Constructs URLs of the form
`{base_url}/{base_path}/{FILE_CODE}_{YEAR}_it.csv.zip`, used by datasets
that publish one ZIP file per year with an `_it` locale suffix.

## Usage

``` r
build_demo_url_a1(info, year, base_url)
```

## Arguments

- info:

  Single-row data.table from the demo registry.

- year:

  Integer year for the data file.

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Returns: "https://demo.istat.it/data/aire/AIRE_2023_it.csv.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "AIR", ][1L, ]
build_demo_url_a1(info, year = 2023,
                  base_url = get_istat_config()$demo$base_url)
} # }
```
