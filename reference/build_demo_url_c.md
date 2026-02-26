# Build Demo URL for Pattern C (Level, Type, and Year)

Constructs URLs of the form
`{base_url}/{base_path}/dati{level}{type}{year}.zip`, used by datasets
that publish files segmented by geographic level and data type.

## Usage

``` r
build_demo_url_c(info, year, level, type, base_url)
```

## Arguments

- info:

  Single-row data.table from the demo registry.

- year:

  Integer year for the data file.

- level:

  Character string specifying the geographic aggregation level.

- type:

  Character string specifying the data completeness type.

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Returns: "https://demo.istat.it/data/tvm/datiregionalicompleti2024.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "TVM", ][1L, ]
build_demo_url_c(info, year = 2024, level = "regionali",
                 type = "completi", base_url = get_istat_config()$demo$base_url)
} # }
```
