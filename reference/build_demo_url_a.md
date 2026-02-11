# Build Demo URL for Pattern A (Year-Indexed)

Constructs URLs of the form
`{base_url}/{base_path}/{FILE_CODE}{YEAR}.csv.zip`, used by datasets
that publish one ZIP file per year with the year appended to the file
code.

## Usage

``` r
build_demo_url_a(info, year, base_url)
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
# Returns: "https://demo.istat.it/data/d7b/D7B2024.csv.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "d7b", ][1L, ]
build_demo_url_a(info, year = 2024,
                 base_url = get_istat_config()$demo$base_url)
} # }
```
