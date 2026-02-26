# Build Demo URL for Pattern F (Static File)

Constructs URLs of the form `{base_url}/{base_path}/{static_filename}`,
used by datasets that provide a single downloadable file with no year or
parameter variation.

## Usage

``` r
build_demo_url_f(info, base_url)
```

## Arguments

- info:

  Single-row data.table from the demo registry.

- base_url:

  Character string with the demo.istat.it base URL.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Returns: "https://demo.istat.it/data/tva/tavole%20attuariali.zip"
registry <- get_demo_registry()
info <- registry[registry$code == "TVA", ][1L, ]
build_demo_url_f(info, base_url = get_istat_config()$demo$base_url)
} # }
```
