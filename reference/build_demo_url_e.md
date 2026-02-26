# Build Demo URL for Pattern E (Subtype-Indexed)

Constructs URLs of the form
`{base_url}/{base_path}/{file_code}_{subtype}_{year}.zip`, used by
datasets that publish separate ZIP files per data subtype and year.

## Usage

``` r
build_demo_url_e(info, year, subtype, base_url)
```

## Arguments

- info:

  Single-row data.table from the demo registry.

- year:

  Integer year for the data file.

- subtype:

  Character string specifying the data subtype (e.g., `"nascita"`,
  `"cittadinanza"`).

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Returns: "https://demo.istat.it/data/rcs/Dati_RCS_cittadinanza_2025.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "RCS", ][1L, ]
build_demo_url_e(info, year = 2025, subtype = "cittadinanza",
                 base_url = get_istat_config()$demo$base_url)
} # }
```
