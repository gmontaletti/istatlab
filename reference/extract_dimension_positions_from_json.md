# Extract Dimension Positions from JSON Response

Internal function to extract dimension IDs and their 1-based key
positions from the JSON datastructure response. SDMX positions are
0-based, so this function adds 1 to convert them. If a dimension does
not declare a position, the iteration index is used as fallback.

## Usage

``` r
extract_dimension_positions_from_json(json_data)
```

## Arguments

- json_data:

  Parsed JSON from datastructure endpoint (as list)

## Value

Named integer vector mapping dimension IDs to their 1-based positions
(e.g., `c(FREQ = 1L, REF_AREA = 2L, EDITION = 7L)`). Returns an empty
named integer vector on error.
