# Build the Demo.istat.it Dataset Registry

Constructs a `data.table` containing metadata for all datasets published
on demo.istat.it. The registry is built in memory from hard-coded
entries that mirror the portal's file structure.

## Usage

``` r
get_demo_registry()
```

## Value

A `data.table` with one row per dataset and the following columns:

- code:

  Short registry code (e.g., `"D7B"`, `"POS"`)

- url_pattern:

  Download URL pattern identifier: `"A"`, `"B"`, `"C"`, or `"D"`

- base_path:

  URL path segment used in the download URL

- file_code:

  Code used in filenames (may differ from `code`)

- category:

  Thematic category string

- description_it:

  Italian-language description

- description_en:

  English-language description

- year_start:

  First available year (integer)

- year_end:

  Last available year (integer or `NA` for ongoing series)

- territories:

  Comma-separated territory levels (Pattern B only, `NA` otherwise)

- levels:

  Comma-separated geographic levels (Pattern C only, `NA` otherwise)

- types:

  Comma-separated data types (Pattern C only, `NA` otherwise)

- data_types:

  Comma-separated data types (Pattern D only, `NA` otherwise)

- geo_levels:

  Comma-separated geographic levels (Pattern D only, `NA` otherwise)
