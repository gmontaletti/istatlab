# Parse HVD Dataflow JSON Response

Extracts dataflow identifiers, names, descriptions, and agencies from a
parsed SDMX JSON response. Handles structural differences between v1 and
v2 response formats.

## Usage

``` r
.parse_hvd_dataflows(json_data, api_version)
```

## Arguments

- json_data:

  Parsed JSON list from the dataflow endpoint.

- api_version:

  Character string indicating the API version used.

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns `id`, `name`, `description`, and `agency`.
