# Build Demo URL for Pattern G (Year-Indexed CSV)

Constructs URLs of the form
`{base_url}/{base_path}/{file_code}{year}.csv`, used by datasets that
publish plain CSV files (not zipped) with the year appended to the file
code.

## Usage

``` r
build_demo_url_g(info, year, base_url)
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
# Returns: "https://demo.istat.it/data/ism/Decessi-Tassi-Anno_2020.csv"
registry <- get_demo_registry()
info <- registry[registry$code == "ISM", ][1L, ]
build_demo_url_g(info, year = 2020,
                 base_url = get_istat_config()$demo$base_url)
} # }
```
