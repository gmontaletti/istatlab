# Build Demo URL for Pattern B (Territory-Indexed)

Constructs URLs of the form
`{base_url}/{base_path}/{FILE_CODE}_{YEAR}_it_{TERRITORY}.zip`, used by
datasets that publish separate ZIP files per geographic territory.

## Usage

``` r
build_demo_url_b(info, year, territory, base_url)
```

## Arguments

- info:

  Single-row data.table from the demo registry.

- year:

  Integer year for the data file.

- territory:

  Character string specifying the geographic territory.

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Returns: "https://demo.istat.it/data/posas/POSAS_2025_it_Comuni.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "posas", ][1L, ]
build_demo_url_b(info, year = 2025, territory = "Comuni",
                 base_url = get_istat_config()$demo$base_url)
} # }
```
